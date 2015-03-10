package main

/* HOW TO RUN THE TEST

Be sure you have a running ngrok instance. This is needed so klient can connect
to our kontrol. Run it with:

	./ngrok -authtoken="CMY-UsZMWdx586A3tA0U" -subdomain="kloud-test" 4099

Postgres and mongodb url is same is in the koding dev config. below is an example go test command:

	KLOUD_KONTROL_URL="http://kloud-test.ngrok.com/kite"
	KLOUD_MONGODB_URL=192.168.59.103:27017/koding
	KONTROL_POSTGRES_PASSWORD=kontrolapplication KONTROL_STORAGE=postgres
	KONTROL_POSTGRES_USERNAME=kontrolapplication KONTROL_POSTGRES_DBNAME=social
	KONTROL_POSTGRES_HOST=192.168.59.103 go test -v -timeout 20m

To execute the tests in Parallel append the flag (where the number is the number of CPU Cores):

	-parallel 8

To get profile files first compile a binary and call that particular binary with additional flags:

	go test -c

	KLOUD_KONTROL_URL="http://kloud-test.ngrok.com/kite"
	KLOUD_MONGODB_URL=192.168.59.103:27017/koding
	KONTROL_POSTGRES_PASSWORD=kontrolapplication KONTROL_STORAGE=postgres
	KONTROL_POSTGRES_USERNAME=kontrolapplication KONTROL_POSTGRES_DBNAME=social
	KONTROL_POSTGRES_HOST=192.168.59.103 ./kloud.test -test.v -test.timeout 20m
	-test.cpuprofile=kloud_cpu.prof -test.memprofile=kloud_mem.prof


Create a nice graph from the cpu profile
	go tool pprof --pdf kloud.test  kloud_cpu.prof > kloud_cpu.pdf
*/

import (
	"errors"
	"fmt"
	"log"
	"net/url"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kontrol"
	"github.com/koding/kite/protocol"
	"github.com/koding/kite/testkeys"
	"github.com/koding/kite/testutil"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/keys"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/multiec2"
	kloudprotocol "koding/kites/kloud/protocol"
	"koding/kites/kloud/provider/koding"
	"koding/kites/kloud/sshutil"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

var (
	kloudKite *kite.Kite
	kld       *kloud.Kloud
	remote    *kite.Client
	conf      *config.Config
	provider  *koding.Provider

	errNoSnapshotFound = errors.New("No snapshot found for the given user")
)

type args struct {
	MachineId  string
	SnapshotId string
}

type singleUser struct {
	MachineId  string
	PrivateKey string
	PublicKey  string
	AccountId  bson.ObjectId
}

func init() {
	conf = config.New()
	conf.Username = "testuser"

	conf.KontrolURL = os.Getenv("KLOUD_KONTROL_URL")
	if conf.KontrolURL == "" {
		conf.KontrolURL = "http://localhost:4099/kite"
	}

	conf.KontrolKey = testkeys.Public
	conf.KontrolUser = "testuser"
	conf.KiteKey = testutil.NewKiteKey().Raw

	// Power up our own kontrol kite for self-contained tests
	kontrol.DefaultPort = 4099
	kntrl := kontrol.New(conf.Copy(), "0.1.0", testkeys.Public, testkeys.Private)
	kntrl.SetStorage(kontrol.NewPostgres(nil, kntrl.Kite.Log))

	go kntrl.Run()
	<-kntrl.Kite.ServerReadyNotify()

	// Power up kloud kite
	kloudKite = kite.New("kloud", "0.0.1")
	kloudKite.Config = conf.Copy()
	kloudKite.Config.Port = 4002
	kiteURL := &url.URL{Scheme: "http", Host: "localhost:4002", Path: "/kite"}
	_, err := kloudKite.Register(kiteURL)
	if err != nil {
		log.Fatal(err)
	}

	provider = newKodingProvider()

	// Add Kloud handlers
	kld := newKloud(provider)
	kloudKite.HandleFunc("build", kld.Build)
	kloudKite.HandleFunc("destroy", kld.Destroy)
	kloudKite.HandleFunc("start", kld.Start)
	kloudKite.HandleFunc("stop", kld.Stop)
	kloudKite.HandleFunc("reinit", kld.Reinit)
	kloudKite.HandleFunc("restart", kld.Restart)
	kloudKite.HandleFunc("resize", kld.Resize)
	kloudKite.HandleFunc("event", kld.Event)
	kloudKite.HandleFunc("createSnapshot", kld.CreateSnapshot)
	kloudKite.HandleFunc("deleteSnapshot", kld.DeleteSnapshot)

	go kloudKite.Run()
	<-kloudKite.ServerReadyNotify()

	user := kite.New("user", "0.0.1")
	user.Config = conf.Copy()

	kloudQuery := &protocol.KontrolQuery{
		Username:    "testuser",
		Environment: conf.Environment,
		Name:        "kloud",
	}
	kites, err := user.GetKites(kloudQuery)
	if err != nil {
		log.Fatal(err)
	}

	// Get the caller
	remote = kites[0]
	if err := remote.Dial(); err != nil {
		log.Fatal(err)
	}
}

func TestBuild(t *testing.T) {
	t.Parallel()
	username := "testuser1"
	userData, err := createUser(username)
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineId); err != nil {
		t.Fatal(err)
	}

	// now try to ssh into the machine with temporary private key we created in
	// the beginning
	if err := checkSSHKey(userData.MachineId, userData.PrivateKey); err != nil {
		t.Error(err)
	}

	// invalid calls after build
	if err := build(userData.MachineId); err == nil {
		t.Error("`build` method can not be called on `running` machines.")
	}

	if err := destroy(userData.MachineId); err != nil {
		t.Error(err)
	}
}

func TestStop(t *testing.T) {
	t.Parallel()
	username := "testuser2"
	userData, err := createUser(username)
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineId); err != nil {
		t.Fatal(err)
	}

	log.Println("Stopping machine")
	if err := stop(userData.MachineId); err != nil {
		t.Fatal(err)
	}

	// the following calls should give an error, if not there is a problem
	if err := build(userData.MachineId); err == nil {
		t.Error("`build` method can not be called on `stopped` machines.")
	}

	if err := stop(userData.MachineId); err == nil {
		t.Error("`stop` method can not be called on `stopped` machines.")
	}

	if err := destroy(userData.MachineId); err != nil {
		t.Error(err)
	}
}

func TestStart(t *testing.T) {
	t.Parallel()
	username := "testuser3"
	userData, err := createUser(username)
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineId); err != nil {
		t.Fatal(err)
	}

	log.Println("Stopping machine to start machine again")
	if err := stop(userData.MachineId); err != nil {
		t.Fatal(err)
	}

	log.Println("Starting machine")
	if err := start(userData.MachineId); err != nil {
		t.Errorf("`start` method can not be called on `stopped` machines: %s\n", err)
	}

	if err := start(userData.MachineId); err == nil {
		t.Error("`start` method can not be called on `started` machines.")
	}

	if err := destroy(userData.MachineId); err != nil {
		t.Error(err)
	}
}

func TestSnapshot(t *testing.T) {
	t.Parallel()
	username := "testuser4"
	userData, err := createUser(username)
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineId); err != nil {
		t.Fatal(err)
	}

	log.Println("Creating snapshot")
	if err := createSnapshot(userData.MachineId); err != nil {
		t.Error(err)
	}

	log.Println("Retrieving snapshot id")
	snapshotId, err := getSnapshotId(userData.MachineId, userData.AccountId)
	if err != nil {
		t.Fatal(err)
	}

	log.Println("Deleting snapshot")
	if err := deleteSnapshot(userData.MachineId, snapshotId); err != nil {
		t.Error(err)
	}

	// once deleted there shouldn't be any snapshot data in MongoDB
	log.Println("Checking snapshot data in MongoDB")
	if err := checkSnapshotMongoDB(snapshotId, userData.AccountId); err != errNoSnapshotFound {
		t.Error(err)
	}

	// also check AWS, be sure it's been deleted
	log.Println("Checking snapshot data in AWS")
	err = checkSnapshotAWS(userData.MachineId, snapshotId)
	if err != nil && !isSnapshotNotFoundError(err) {
		t.Error(err)
	}

	if err := destroy(userData.MachineId); err != nil {
		t.Error(err)
	}
}

func TestResize(t *testing.T) {
	t.Parallel()
	username := "testuser"
	userData, err := createUser(username)
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineId); err != nil {
		t.Fatal(err)
	}

	resize := func(storageWant int) {
		log.Printf("Resizing machine to %dGB\n", storageWant)
		err = provider.Session.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				bson.ObjectIdHex(userData.MachineId),
				bson.M{
					"$set": bson.M{
						"meta.storage_size": storageWant,
					},
				},
			)
		})
		if err != nil {
			t.Error(err)
		}

		if err := resize(userData.MachineId); err != nil {
			t.Error(err)
		}

		storageGot, err := getAmazonStorageSize(userData.MachineId)
		if err != nil {
			t.Error(err)
		}

		if storageGot != storageWant {
			t.Errorf("Resizing completed but storage sizes do not match. Want: %dGB, Got: %dGB",
				storageWant,
				storageGot,
			)
		}
	}

	resize(5) // first increase
	resize(7) // second increase
	resize(9) // third increase

	log.Println("Destroying machine")
	if err := destroy(userData.MachineId); err != nil {
		t.Error(err)
	}
}

// createUser creates a test user in jUsers and a single jMachine document.
func createUser(username string) (*singleUser, error) {
	privateKey, publicKey, err := sshutil.TemporaryKey()
	if err != nil {
		return nil, err
	}

	// cleanup old document
	provider.Session.Run("jUsers", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"username": username})
	})

	provider.Session.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"profile.nickname": username})
	})

	accountId := bson.NewObjectId()
	account := &models.Account{
		Id: accountId,
		Profile: models.AccountProfile{
			Nickname: username,
		},
	}

	if err := provider.Session.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Insert(&account)
	}); err != nil {
		return nil, err
	}

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

	if err := provider.Session.Run("jUsers", func(c *mgo.Collection) error {
		return c.Insert(&user)
	}); err != nil {
		return nil, err
	}

	// later we can add more users with "Owner:false" to test sharing capabilities
	users := []models.Permissions{
		{Id: userId, Sudo: true, Owner: true},
	}

	machineId := bson.NewObjectId()
	machine := &koding.MachineDocument{
		Id:         machineId,
		Label:      "",
		Domain:     username + ".dev.koding.io",
		Credential: username,
		Provider:   "koding",
		CreatedAt:  time.Now().UTC(),
		Meta: bson.M{
			"region":        "eu-west-1",
			"instance_type": "t2.micro",
			"storage_size":  3,
			"alwaysOn":      false,
		},
		Users:  users,
		Groups: make([]models.Permissions, 0),
	}
	machine.Assignee.InProgress = false
	machine.Assignee.AssignedAt = time.Now().UTC()
	machine.Status.State = machinestate.NotInitialized.String()
	machine.Status.ModifiedAt = time.Now().UTC()

	if err := provider.Session.Run("jMachines", func(c *mgo.Collection) error {
		return c.Insert(&machine)
	}); err != nil {
		return nil, err
	}

	return &singleUser{
		MachineId:  machineId.Hex(),
		PrivateKey: privateKey,
		PublicKey:  publicKey,
		AccountId:  accountId,
	}, nil
}

func build(id string) error {
	buildArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("build", buildArgs)
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
			EventId: buildArgs.MachineId,
			Type:    "build",
		},
	})

	return listenEvent(eArgs, machinestate.Running)

}

func checkSSHKey(id, privateKey string) error {
	// now try to ssh into the machine with temporary private key we created in
	// the beginning
	machine, err := provider.Get(id)
	if err != nil {
		return err
	}

	sshConfig, err := sshutil.SshConfig("root", privateKey)
	if err != nil {
		return err
	}

	log.Printf("Connecting to machine with ip '%s' via ssh\n", machine.IpAddress)
	sshClient, err := sshutil.ConnectSSH(machine.IpAddress+":22", sshConfig)
	if err != nil {
		return err
	}

	log.Printf("Testing SSH deployment")
	output, err := sshClient.StartCommand("whoami")
	if err != nil {
		return err
	}

	if strings.TrimSpace(string(output)) != "root" {
		return fmt.Errorf("Whoami result should be root, got: %s", string(output))
	}

	return nil
}

func destroy(id string) error {
	destroyArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("destroy", destroyArgs)
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
			EventId: destroyArgs.MachineId,
			Type:    "destroy",
		},
	})

	return listenEvent(eArgs, machinestate.Terminated)
}

func start(id string) error {
	startArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("start", startArgs)
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
			EventId: startArgs.MachineId,
			Type:    "start",
		},
	})

	return listenEvent(eArgs, machinestate.Running)
}

func stop(id string) error {
	stopArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("stop", stopArgs)
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
			EventId: stopArgs.MachineId,
			Type:    "stop",
		},
	})

	return listenEvent(eArgs, machinestate.Stopped)
}

func reinit(id string) error {
	reinitArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("reinit", reinitArgs)
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
			EventId: reinitArgs.MachineId,
			Type:    "reinit",
		},
	})

	return listenEvent(eArgs, machinestate.Running)
}

func restart(id string) error {
	restartArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("restart", restartArgs)
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
			EventId: restartArgs.MachineId,
			Type:    "restart",
		},
	})

	return listenEvent(eArgs, machinestate.Running)
}

func resize(id string) error {
	resizeArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("resize", resizeArgs)
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
			EventId: resizeArgs.MachineId,
			Type:    "resize",
		},
	})

	return listenEvent(eArgs, machinestate.Running)
}

func createSnapshot(id string) error {
	createSnapshotArgs := &args{
		MachineId: id,
	}

	resp, err := remote.Tell("createSnapshot", createSnapshotArgs)
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
			EventId: createSnapshotArgs.MachineId,
			Type:    "createSnapshot",
		},
	})

	return listenEvent(eArgs, machinestate.Running)
}

func deleteSnapshot(id, snapshotId string) error {
	deleteSnapshotArgs := &args{
		MachineId:  id,
		SnapshotId: snapshotId,
	}

	resp, err := remote.Tell("deleteSnapshot", deleteSnapshotArgs)
	if err != nil {
		return err
	}

	result, err := resp.Bool()
	if err != nil {
		return err
	}

	if !result {
		return errors.New("Successfull snapshot deletion should return true, got false")
	}

	return nil
}

// listenEvent calls the event method of kloud with the given arguments until
// the desiredState is received. It times out if the desired state is not
// reached in 10 miunuts.
func listenEvent(args kloud.EventArgs, desiredState machinestate.State) error {
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

		event := e.Event

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

func newKodingProvider() *koding.Provider {
	auth := aws.Auth{
		AccessKey: "AKIAJFKDHRJ7Q5G4MOUQ",
		SecretKey: "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",
	}

	mongoURL := os.Getenv("KLOUD_MONGODB_URL")
	if mongoURL == "" {
		panic("KLOUD_MONGODB_URL is not set")
	}

	modelhelper.Initialize(mongoURL)
	db := modelhelper.Mongo
	domainStorage := koding.NewDomainStorage(db)

	return &koding.Provider{
		Session:           db,
		Kite:              kloudKite,
		Log:               newLogger("koding", true),
		KontrolURL:        conf.KontrolURL,
		KontrolPrivateKey: testkeys.Private,
		KontrolPublicKey:  testkeys.Public,
		Test:              true,
		EC2Clients: multiec2.New(auth, []string{
			"us-east-1",
			"ap-southeast-1",
			"us-west-2",
			"eu-west-1",
		}),
		DNS:           koding.NewDNSClient("dev.koding.io", auth),
		DomainStorage: domainStorage,
		Bucket:        koding.NewBucket("koding-klient", "development/latest", auth),
		KeyName:       keys.DeployKeyName,
		PublicKey:     keys.DeployPublicKey,
		PrivateKey:    keys.DeployPrivateKey,
		Fetcher:       NewTestFetcher(koding.Koding),
	}
}

func newKloud(p *koding.Provider) *kloud.Kloud {
	kld := kloud.New()
	kld.Log = newLogger("kloud", true)
	kld.Locker = p
	kld.Storage = p
	kld.DomainStorage = p.DomainStorage
	kld.Domainer = p.DNS
	kld.Debug = true
	kld.AddProvider("koding", p)
	return kld
}

func getAmazonStorageSize(machineId string) (int, error) {
	m, err := provider.Get(machineId)
	if err != nil {
		return 0, err
	}

	a, err := provider.NewClient(m)
	if err != nil {
		return 0, err
	}

	instance, err := a.Instance(a.Id())
	if err != nil {
		return 0, err
	}

	if len(instance.BlockDevices) == 0 {
		return 0, fmt.Errorf("fatal error: no block device available")
	}

	// we need in a lot of placages!
	oldVolumeId := instance.BlockDevices[0].VolumeId

	oldVolResp, err := a.Client.Volumes([]string{oldVolumeId}, ec2.NewFilter())
	if err != nil {
		return 0, err
	}

	volSize := oldVolResp.Volumes[0].Size
	currentSize, err := strconv.Atoi(volSize)
	if err != nil {
		return 0, err
	}

	return currentSize, nil
}

func getSnapshotId(machineId string, accountId bson.ObjectId) (string, error) {
	var snapshot *koding.SnapshotDocument
	if err := provider.Session.Run("jSnapshots", func(c *mgo.Collection) error {
		return c.Find(bson.M{"originId": accountId, "machineId": bson.ObjectIdHex(machineId)}).One(&snapshot)
	}); err != nil {
		return "", err
	}

	return snapshot.SnapshotId, nil
}

func checkSnapshotAWS(machineId, snapshotId string) error {
	m, err := provider.Get(machineId)
	if err != nil {
		return err
	}

	a, err := provider.NewClient(m)
	if err != nil {
		return err
	}

	_, err = a.Client.Snapshots([]string{snapshotId}, ec2.NewFilter())
	return err // nil means it exists
}

func checkSnapshotMongoDB(snapshotId string, accountId bson.ObjectId) error {
	var err error
	var count int

	err = provider.Session.Run("jSnapshots", func(c *mgo.Collection) error {
		count, err = c.Find(bson.M{
			"originId":   accountId,
			"snapshotId": snapshotId,
		}).Count()
		return err
	})

	if err != nil {
		log.Printf("Could not fetch %v: err: %v", snapshotId, err)
		return errors.New("could not check Snapshot existency")
	}

	if count == 0 {
		return errNoSnapshotFound
	}

	return nil

}

func isSnapshotNotFoundError(err error) bool {
	ec2Error, ok := err.(*ec2.Error)
	if !ok {
		return false
	}

	return ec2Error.Code == "InvalidSnapshot.NotFound"
}

// TestFetcher satisfies the fetcher interface
type TestFetcher struct {
	Plan koding.Plan
}

func NewTestFetcher(plan koding.Plan) *TestFetcher {
	return &TestFetcher{
		Plan: plan,
	}
}

func (t *TestFetcher) Fetch(m *kloudprotocol.Machine) (*koding.FetcherResponse, error) {
	return &koding.FetcherResponse{
		Plan:  t.Plan,
		State: "active",
	}, nil
}
