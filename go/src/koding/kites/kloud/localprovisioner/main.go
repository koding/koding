package main

import (
	"bytes"
	"fmt"
	"io/ioutil"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/common"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/plans"
	"koding/kites/kloud/provider/aws"
	"koding/kites/kloud/provider/koding"
	"koding/kites/kloud/provider/softlayer"
	"koding/kites/kloud/sshutil"
	"koding/kites/kloud/userdata"
	"koding/kites/terraformer"
	"log"
	"net/url"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kontrol"
	"github.com/koding/kite/protocol"
	"github.com/koding/kite/testkeys"
	"github.com/koding/kite/testutil"
	"github.com/koding/klient/app"
	"github.com/koding/logging"

	// Klient uses vendored Kite, so we need to export it explicitly to make use of it
	klKite "github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite"
	klKiteConf "github.com/koding/klient/Godeps/_workspace/src/github.com/koding/kite/config"
)

var (
	kloudKite      *kite.Kite
	klientKite     *klKite.Kite
	kld            *kloud.Kloud
	conf           *config.Config
	kodingProvider *koding.Provider
	awsProvider    *awsprovider.Provider
	slProvider     *softlayer.Provider
)

type singleUser struct {
	MachineIds      []bson.ObjectId
	MachineLabels   []string
	StackId         string
	StackTemplateId string
	PrivateKey      string
	PublicKey       string
	AccountId       bson.ObjectId
	Identifiers     []string
	Remote          *kite.Client
}

type createUserOptions struct {
	Username     string
	Groupname    string
	Label        string
	Region       string
	Provider     string
	Template     string
	MachineCount int
}

func main() {
	// The default hanlder somehow overriden by one of the imported packages
	// here. I've searched for hours with no luck. So I'm restoring it again
	// back.
	handler := logging.NewWriterHandler(os.Stderr)
	handler.Colorize = true
	logging.DefaultHandler = handler

	if err := realMain(); err != nil {
		log.Fatalln(err)
	}
}

func realMain() error {
	if err := startInstances(); err != nil {
		return err
	}

	if err := sendPingToKlient(); err != nil {
		return err
	}

	log.Println("Setting up Vagrant provisioning ")
	if err := applyVagrantCommand(); err != nil {
		return err
	}

	return nil
}

// sendPingToKlient connects to klient by searching for it via Kontrol and
// sends a ping message to it. Handy to debug klient if needed
func sendPingToKlient() error {
	// now create a test kite which calls kloud or klient, respectively
	queryString := klientKite.Kite().String()

	userKite := kite.New("user", "0.0.1")
	username := "testuser"
	c := conf.Copy()
	c.KiteKey = testutil.NewKiteKeyUsername(username).Raw
	c.Username = username
	userKite.Config = c
	// userKite.SetLogLevel(kite.DEBUG) // enable if needed

	userKite.Log.Info("Searching for klient: %s", queryString)
	klientRef, err := klient.NewWithTimeout(userKite, queryString, time.Minute*1)
	if err != nil {
		return err
	}
	defer klientRef.Close()

	userKite.Log.Info("Sending a ping message")
	if err := klientRef.Ping(); err != nil {
		return err
	}

	return nil
}

func applyVagrantCommand() error {
	localTemplate := `{
    "resource": {
        "vagrantkite_build": {
            "%s": {
                "filePath": "%s",
                "queryString": "%s",
                "cpus": 2,
                "memory": 2048
            }
        }
    }
}`

	curdir, err := os.Getwd()
	if err != nil {
		return err
	}

	label := "myfirstvm"
	testQueryString := klientKite.Kite().String()
	testFilePath := filepath.Join(curdir, "localprovtest")

	terraformTemplate := fmt.Sprintf(localTemplate,
		label,
		testFilePath,
		testQueryString,
	)

	groupname := "koding"

	opts := &createUserOptions{
		Username:     "arslan",
		Label:        label,
		Groupname:    groupname,
		Region:       "testRegion",
		Provider:     "vagrant",
		Template:     terraformTemplate,
		MachineCount: 1,
	}

	userData, err := createUser(opts)
	if err != nil {
		return err
	}

	fmt.Printf("userData = %+v\n", userData)
	remote := userData.Remote

	applyArgs := &kloud.TerraformApplyRequest{
		StackId:   userData.StackId,
		GroupName: groupname,
	}

	resp, err := remote.Tell("apply", applyArgs)
	if err != nil {
		return err
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		return err
	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: userData.StackId,
			Type:    "apply",
		},
	})

	if err := listenEvent(eArgs, machinestate.Terminated, remote); err != nil {
		return err
	}

	return nil
}

// startInstances startes the following applications in order:
// 1. kontrol
// 2. kloud
// 3. terraformer
// 4. klient
//
// All applications register themself to kontrol.
func startInstances() error {
	repoPath, err := currentRepoPath()
	if err != nil {
		return err
	}

	conf = testutil.NewConfig() // username is "testuser"
	conf.Environment = "localhost-env"
	conf.Region = "localhost-region"
	conf.KontrolURL = os.Getenv("KLOUD_KONTROL_URL")
	if conf.KontrolURL == "" {
		conf.KontrolURL = "http://localhost:4444/kite"
	}
	conf.Transport = config.XHRPolling

	// Power up our own kontrol kite for self-contained tests
	log.Println("Starting Kontrol Test Instance")
	kontrol.DefaultPort = 4444
	kntrl := kontrol.New(conf.Copy(), "0.1.0")
	p := kontrol.NewPostgres(nil, kntrl.Kite.Log)
	kntrl.SetKeyPairStorage(p)
	kntrl.SetStorage(p)
	kntrl.AddKeyPair("", testkeys.Public, testkeys.Private)

	go kntrl.Run()
	<-kntrl.Kite.ServerReadyNotify()

	// Power up kloud kite
	log.Println("Starting Kloud Test Instance")
	kloudKite = kite.New("kloud", "0.0.1")
	kloudKite.Config = conf.Copy()
	kloudKite.Config.Port = 4002
	kiteURL := &url.URL{Scheme: "http", Host: "localhost:4002", Path: "/kite"}
	_, err = kloudKite.Register(kiteURL)
	if err != nil {
		return fmt.Errorf("kloud: %s", err)
	}

	kodingProvider, awsProvider, slProvider = providers()

	// Add Kloud handlers
	kld := kloudWithProviders(kodingProvider, awsProvider, slProvider)
	kloudKite.HandleFunc("plan", kld.Plan)
	kloudKite.HandleFunc("apply", kld.Apply)
	kloudKite.HandleFunc("bootstrap", kld.Bootstrap)
	kloudKite.HandleFunc("authenticate", kld.Authenticate)

	kloudKite.HandleFunc("build", kld.Build)
	kloudKite.HandleFunc("destroy", kld.Destroy)
	kloudKite.HandleFunc("stop", kld.Stop)
	kloudKite.HandleFunc("start", kld.Start)
	kloudKite.HandleFunc("reinit", kld.Reinit)
	kloudKite.HandleFunc("resize", kld.Resize)
	kloudKite.HandleFunc("restart", kld.Restart)
	kloudKite.HandleFunc("event", kld.Event)
	kloudKite.HandleFunc("createSnapshot", kld.CreateSnapshot)
	kloudKite.HandleFunc("deleteSnapshot", kld.DeleteSnapshot)

	go kloudKite.Run()
	<-kloudKite.ServerReadyNotify()

	// Power up our terraformer kite
	log.Println("Starting Terraform Test Instance")
	tConf := &terraformer.Config{
		Port:        2300,
		Region:      "dev",
		Environment: "dev",
		AWS: terraformer.AWS{
			Key:    os.Getenv("TERRAFORMER_KEY"),
			Secret: os.Getenv("TERRAFORMER_SECRET"),
			Bucket: "koding-terraformer-state-dev",
		},
		LocalStorePath: filepath.Join(repoPath, filepath.FromSlash("go/data/terraformer")),
	}

	t, err := terraformer.New(tConf, common.NewLogger("terraformer", true))
	if err != nil {
		return fmt.Errorf("terraformer: %s", err)
	}

	terraformerKite, err := terraformer.NewKite(t, tConf)
	if err != nil {
		log.Fatal("terraformer ", err.Error())
	}

	// no need to register to kontrol, kloud talks directly via a secret key
	terraformerKite.Config = conf.Copy()
	terraformerKite.Config.Port = 2300

	go terraformerKite.Run()
	<-terraformerKite.ServerReadyNotify()

	log.Println("=== Test instances are up and ready!")

	// hashicorp.terraform outputs many logs, discard them
	// log.SetOutput(ioutil.Discard)

	log.Println("=== Starting Klient now!!!")
	startKlient()
	return nil
}

func startKlient() {
	dbPath := ""
	u, err := user.Current()
	if err == nil {
		dbPath = filepath.Join(u.HomeDir, "/.config/koding/klient.bolt")
	}

	klientConf := &app.KlientConfig{
		Name:        "klient",
		Environment: "localhost",
		Region:      "localhost",
		Version:     "0.0.1",
		DBPath:      dbPath,
		IP:          "",
		Port:        56789,
		RegisterURL: "http://localhost:56789/kite",
		KontrolURL:  conf.KontrolURL,
		// Debug:       true,
	}

	a := app.NewKlient(klientConf)
	klientKite = a.Kite()
	klientKite.Config = &klKiteConf.Config{
		Username:    conf.Username,
		Environment: conf.Environment,
		Region:      conf.Region,
		Id:          conf.Id,
		Port:        klientConf.Port,
		KiteKey:     conf.KiteKey,
		Transport:   klKiteConf.Transports[conf.Transport.String()],
		KontrolURL:  conf.KontrolURL,
		KontrolKey:  conf.KontrolKey,
		KontrolUser: conf.KontrolUser,
	}

	// Run Forrest, Run!
	go a.Run()
	<-klientKite.ServerReadyNotify()
}

func providers() (*koding.Provider, *awsprovider.Provider, *softlayer.Provider) {
	c := credentials.NewStaticCredentials(os.Getenv("KLOUD_ACCESSKEY"), os.Getenv("KLOUD_SECRETKEY"), "")

	mongoURL := os.Getenv("KLOUD_MONGODB_URL")
	if mongoURL == "" {
		panic("KLOUD_MONGODB_URL is not set")
	}

	modelhelper.Initialize(mongoURL)
	db := modelhelper.Mongo

	dnsInstance := dnsclient.NewRoute53Client(c, "dev.koding.io")
	dnsStorage := dnsstorage.NewMongodbStorage(db)
	usd := &userdata.Userdata{
		Keycreator: &keycreator.Key{
			KontrolURL:        conf.KontrolURL,
			KontrolPrivateKey: testkeys.Private,
			KontrolPublicKey:  testkeys.Public,
		},
		Bucket: userdata.NewBucket("koding-klient", "development/latest", c),
	}
	opts := &amazon.ClientOptions{
		Credentials: c,
		Regions:     amazon.ProductionRegions,
		Log:         common.NewLogger("koding", true),
	}

	ec2clients, err := amazon.NewClients(opts)
	if err != nil {
		panic(err)
	}

	slclient, err := sl.NewSoftlayer(
		os.Getenv("KLOUD_TESTACCOUNT_SLUSERNAME"),
		os.Getenv("KLOUD_TESTACCOUNT_SLAPIKEY"),
	)
	if err != nil {
		panic(err)
	}

	kdp := &koding.Provider{
		DB:             db,
		Log:            opts.Log,
		DNSClient:      dnsInstance,
		DNSStorage:     dnsStorage,
		Kite:           kloudKite,
		EC2Clients:     ec2clients,
		Userdata:       usd,
		PaymentFetcher: NewTestFetcher("hobbyist"),
		CheckerFetcher: NewTestChecker(),
	}

	awsp := &awsprovider.Provider{
		DB:         db,
		Log:        common.NewLogger("kloud-aws", true),
		DNSClient:  dnsInstance,
		DNSStorage: dnsStorage,
		Kite:       kloudKite,
		Userdata:   usd,
	}

	slp := &softlayer.Provider{
		DB:         db,
		Log:        common.NewLogger("kloud-provider", true),
		DNSClient:  dnsInstance,
		DNSStorage: dnsStorage,
		SLClient:   slclient,
		Kite:       kloudKite,
		Userdata:   usd,
	}

	return kdp, awsp, slp
}

func kloudWithProviders(p *koding.Provider, a *awsprovider.Provider, s *softlayer.Provider) *kloud.Kloud {
	debugEnabled := true
	kloudLogger := common.NewLogger("kloud", debugEnabled)
	sess := &session.Session{
		DB:         p.DB,
		Kite:       p.Kite,
		DNSClient:  p.DNSClient,
		DNSStorage: p.DNSStorage,
		AWSClients: p.EC2Clients,
		Userdata:   p.Userdata,
		Log:        kloudLogger,
	}

	kld := kloud.New()
	kld.ContextCreator = func(ctx context.Context) context.Context {
		return session.NewContext(ctx, sess)
	}

	userPrivateKey, userPublicKey := userMachinesKeys(
		os.Getenv("KLOUD_USER_PUBLICKEY"),
		os.Getenv("KLOUD_USER_PRIVATEKEY"),
	)

	kld.PublicKeys = &publickeys.Keys{
		KeyName:    publickeys.DeployKeyName,
		PrivateKey: userPrivateKey,
		PublicKey:  userPublicKey,
	}
	kld.Log = kloudLogger
	kld.DomainStorage = p.DNSStorage
	kld.Domainer = p.DNSClient
	kld.Locker = p
	kld.AddProvider("koding", p)
	kld.AddProvider("aws", a)
	kld.AddProvider("softlayer", s)
	return kld
}

// TestFetcher satisfies the fetcher interface
type TestFetcher struct {
	Plan string
}

func NewTestFetcher(plan string) *TestFetcher {
	return &TestFetcher{
		Plan: plan,
	}
}

func (t *TestFetcher) Fetch(ctx context.Context, username string) (*plans.PaymentResponse, error) {
	return &plans.PaymentResponse{
		Plan:  t.Plan,
		State: "active",
	}, nil
}

// TestFetcher satisfies the fetcher interface
type TestChecker struct{}

func NewTestChecker() *TestChecker {
	return &TestChecker{}
}

func (t *TestChecker) Fetch(ctx context.Context, plan string) (plans.Checker, error) {
	return &TestPlan{}, nil
}

type TestPlan struct{}

func (t *TestPlan) Total(username string) error {
	return nil
}

func (t *TestPlan) AlwaysOn(username string) error {
	return nil
}

func (t *TestPlan) SnapshotTotal(machineId, username string) error {
	return nil
}

func (t *TestPlan) Storage(wantStorage int, username string) error {
	return nil
}

func (t *TestPlan) AllowedInstances(wantInstance plans.InstanceType) error {
	return nil
}

func (t *TestPlan) NetworkUsage(username string) error {
	return nil
}

func userMachinesKeys(publicPath, privatePath string) (string, string) {
	pubKey, err := ioutil.ReadFile(publicPath)
	if err != nil {
		log.Fatalln(err)
	}
	publicKey := string(pubKey)

	privKey, err := ioutil.ReadFile(privatePath)
	if err != nil {
		log.Fatalln(err)
	}
	privateKey := string(privKey)

	return strings.TrimSpace(privateKey), strings.TrimSpace(publicKey)
}

// currentRepoPath returns the root path of current koding git repository
func currentRepoPath() (string, error) {
	p, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return "", err
	}
	return string(bytes.TrimSpace(p)), nil
}

// createUser creates a test user in jUsers and a single jMachine document.
func createUser(opts *createUserOptions) (*singleUser, error) {
	username := opts.Username
	groupname := opts.Groupname
	region := opts.Region
	provider := opts.Provider
	template := opts.Template
	machineCount := opts.MachineCount
	label := opts.Label

	privateKey, publicKey, err := sshutil.TemporaryKey()
	if err != nil {
		return nil, err
	}

	db := awsProvider.DB

	// cleanup old document
	db.Run("jUsers", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"username": username})
	})

	db.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"profile.nickname": username})
	})

	db.Run("jGroups", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"slug": groupname})
	})

	// jAccounts
	accountId := bson.NewObjectId()
	account := &models.Account{
		Id: accountId,
		Profile: models.AccountProfile{
			Nickname: username,
		},
	}

	if err := db.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Insert(&account)
	}); err != nil {
		return nil, err
	}

	// jGroups
	groupId := bson.NewObjectId()
	group := &models.Group{
		Id:    groupId,
		Title: groupname,
		Slug:  groupname,
	}

	if err := db.Run("jGroups", func(c *mgo.Collection) error {
		return c.Insert(&group)
	}); err != nil {
		return nil, err
	}

	// add relation between use and group
	relationship := &models.Relationship{
		Id:         bson.NewObjectId(),
		TargetId:   accountId,
		TargetName: "JAccount",
		SourceId:   groupId,
		SourceName: "JGroup",
		As:         "member",
	}

	if err := db.Run("relationships", func(c *mgo.Collection) error {
		return c.Insert(&relationship)
	}); err != nil {
		return nil, err
	}

	// jUsers
	userId := bson.NewObjectId()
	user := &models.User{
		ObjectId:      userId,
		Email:         username + "@" + username + ".com",
		LastLoginDate: time.Now().UTC(),
		RegisteredAt:  time.Now().UTC(),
		Name:          username, // bson equivelant is username
		Password:      "somerandomnumbers",
		Status:        "confirmed",
		SshKeys: []struct {
			Title string `bson:"title"`
			Key   string `bson:"key"`
		}{
			{Key: publicKey},
		},
	}

	if err := db.Run("jUsers", func(c *mgo.Collection) error {
		return c.Insert(&user)
	}); err != nil {
		return nil, err
	}

	// jComputeStack and jStackTemplates
	stackTemplateId := bson.NewObjectId()
	stackTemplate := &models.StackTemplate{
		Id: stackTemplateId,
	}
	stackTemplate.Template.Content = template

	if err := db.Run("jStackTemplates", func(c *mgo.Collection) error {
		return c.Insert(&stackTemplate)
	}); err != nil {
		return nil, err
	}

	// later we can add more users with "Owner:false" to test sharing capabilities
	users := []models.MachineUser{
		{Id: userId, Sudo: true, Owner: true},
	}

	machineLabels := make([]string, machineCount)
	machineIds := make([]bson.ObjectId, machineCount)

	for i := 0; i < machineCount; i++ {
		machineLabel := label + strconv.Itoa(i)
		if machineCount == 1 {
			machineLabel = label
		}

		machineId := bson.NewObjectId()
		machine := &models.Machine{
			ObjectId:   machineId,
			Label:      machineLabel,
			Domain:     username + ".dev.koding.io",
			Provider:   provider,
			CreatedAt:  time.Now().UTC(),
			Users:      users,
			Meta:       make(bson.M, 0),
			Groups:     make([]models.MachineGroup, 0),
			Credential: username,
		}

		machine.Meta["region"] = region
		machine.Meta["instanceType"] = "t2.micro"
		machine.Meta["storage_size"] = 3
		machine.Meta["alwaysOn"] = false
		machine.Assignee.InProgress = false
		machine.Assignee.AssignedAt = time.Now().UTC()
		machine.Status.State = machinestate.NotInitialized.String()
		machine.Status.ModifiedAt = time.Now().UTC()

		machineLabels[i] = machine.Label
		machineIds[i] = machine.ObjectId

		if err := db.Run("jMachines", func(c *mgo.Collection) error {
			return c.Insert(&machine)
		}); err != nil {
			return nil, err
		}
	}

	computeStackId := bson.NewObjectId()
	computeStack := &models.ComputeStack{
		Id:          computeStackId,
		BaseStackId: stackTemplateId,
		Machines:    machineIds,
	}

	if err := db.Run("jComputeStacks", func(c *mgo.Collection) error {
		return c.Insert(&computeStack)
	}); err != nil {
		return nil, err
	}

	userKite := kite.New("user", "0.0.1")
	c := conf.Copy()
	c.KiteKey = testutil.NewKiteKeyUsername(username).Raw
	c.Username = username
	userKite.Config = c

	kloudQuery := &protocol.KontrolQuery{
		Username:    "testuser",
		Environment: c.Environment,
		Name:        "kloud",
	}
	kites, err := userKite.GetKites(kloudQuery)
	if err != nil {
		log.Fatal(err)
	}

	// Get the caller
	remote := kites[0]
	if err := remote.Dial(); err != nil {
		log.Fatal(err)
	}

	identifiers := []string{}

	return &singleUser{
		MachineIds:      machineIds,
		MachineLabels:   machineLabels,
		StackId:         computeStackId.Hex(),
		StackTemplateId: stackTemplate.Id.Hex(),
		PrivateKey:      privateKey,
		PublicKey:       publicKey,
		AccountId:       accountId,
		Identifiers:     identifiers,
		Remote:          remote,
	}, nil
}

// listenEvent calls the event method of kloud with the given arguments until
// the desiredState is received. It times out if the desired state is not
// reached in 10 miunuts.
func listenEvent(args kloud.EventArgs, desiredState machinestate.State, remote *kite.Client) error {
	tryUntil := time.Now().Add(time.Minute * 10)
	for {
		resp, err := remote.Tell("event", args)
		if err != nil {
			return err
		}

		var events []kloud.EventResponse
		if err := resp.Unmarshal(&events); err != nil {
			return err
		}

		e := events[0]
		if e.Error != nil {
			return e.Error
		}

		// fmt.Printf("e = %+v\n", e)

		event := e.Event
		if event.Error != "" {
			return fmt.Errorf("%s: %s", args[0].Type, event.Error)
		}

		if event.Status == desiredState {
			return nil
		}

		if time.Now().After(tryUntil) {
			return fmt.Errorf("Timeout while waiting for state %s", desiredState)
		}

		time.Sleep(2 * time.Second)
		continue // still pending
	}
}
