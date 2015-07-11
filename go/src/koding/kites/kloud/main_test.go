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
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"io/ioutil"
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
	"golang.org/x/net/context"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/common"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/pkg/multiec2"
	"koding/kites/kloud/plans"
	"koding/kites/kloud/provider/koding"
	"koding/kites/kloud/sshutil"
	"koding/kites/kloud/userdata"
	"koding/kites/terraformer"

	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
)

var (
	kloudKite *kite.Kite
	kld       *kloud.Kloud
	conf      *config.Config
	provider  *koding.Provider

	errNoSnapshotFound = errors.New("No snapshot found for the given user")

	machineCount      = 1
	terraformTemplate = `{
    "provider": {
        "aws": {
            "access_key": "${var.access_key}",
            "secret_key": "${var.secret_key}",
            "region": "${var.region}"
        }
    },
    "resource": {
        "aws_instance": {
            "example": {
				"count": %d,
                "instance_type": "t2.micro",
                "ami": "ami-936d9d93"
            }
        }
    }
}`
)

type args struct {
	MachineId        string
	SnapshotId       string
	Provider         string
	TerraformContext string
}

type singleUser struct {
	MachineIds          []bson.ObjectId
	MachineLabels       []string
	StackId             string
	StackTemplateId     string
	PrivateKey          string
	PublicKey           string
	AccountId           bson.ObjectId
	CredentialId        bson.ObjectId
	CredentialPublicKey string
	Remote              *kite.Client
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
	log.Println("Starting Kontrol Test Instance")
	kontrol.DefaultPort = 4099
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
	_, err := kloudKite.Register(kiteURL)
	if err != nil {
		log.Fatal(err)
	}

	provider = kodingProvider()

	// Add Kloud handlers
	kld := kloudWithKodingProvider(provider)
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
		LocalStorePath: "/Users/fatih/Code/koding/go/data/terraformer",
	}

	t, err := terraformer.New(tConf, common.NewLogger("terraformer", false))
	if err != nil {
		log.Fatal(err.Error())
	}

	terraformerKite, err := terraformer.NewKite(t, tConf)
	if err != nil {
		log.Fatal(err.Error())
	}

	// no need to register to kontrol, kloud talks directly via a secret key
	terraformerKite.Config = conf.Copy()
	terraformerKite.Config.Port = 2300

	go terraformerKite.Run()
	<-terraformerKite.ServerReadyNotify()

	log.Println("=== Test instances are up and ready!. Executing now the tests... ===")

	// hashicorp.terraform outputs many logs, discard them
	log.SetOutput(ioutil.Discard)
}

func TestTerraformAuthenticate(t *testing.T) {
	username := "testuser12"
	userData, err := createUser(username, "ap-northeast-1")
	if err != nil {
		t.Fatal(err)
	}

	remote := userData.Remote

	args := &kloud.AuthenticateRequest{
		PublicKeys: []string{userData.CredentialPublicKey},
	}

	_, err = remote.Tell("authenticate", args)
	if err != nil {
		t.Error(err)
	}
}

func TestTerraformBootstrap(t *testing.T) {
	username := "testuser11"
	userData, err := createUser(username, "ap-northeast-1")
	if err != nil {
		t.Fatal(err)
	}

	remote := userData.Remote

	args := &kloud.TerraformBootstrapRequest{
		PublicKeys: []string{userData.CredentialPublicKey},
	}

	_, err = remote.Tell("bootstrap", args)
	if err != nil {
		t.Fatal(err)
	}

	// should be return true always if resource exists
	_, err = remote.Tell("bootstrap", args)
	if err != nil {
		t.Error(err)
	}

	// now destroy them all
	args.Destroy = true
	_, err = remote.Tell("bootstrap", args)
	if err != nil {
		t.Error(err)
	}
}

func TestTerraformPlan(t *testing.T) {
	t.Parallel()
	username := "testuser0"
	userData, err := createUser(username, "ap-northeast-1")
	if err != nil {
		t.Fatal(err)
	}

	remote := userData.Remote

	args := &kloud.TerraformPlanRequest{
		StackTemplateId: userData.StackTemplateId,
	}

	resp, err := remote.Tell("plan", args)
	if err != nil {
		t.Fatal(err)
	}

	var result *kloud.Machines
	if err := resp.Unmarshal(&result); err != nil {
		t.Fatal(err)
	}

	inLabels := func(label string) bool {
		for _, l := range userData.MachineLabels {
			if l == label {
				return true
			}
		}
		return false
	}

	for _, machine := range result.Machines {
		if !inLabels(machine.Label) {
			t.Errorf("plan label: have: %+v got: %s\n", userData.MachineLabels, machine.Label)
		}

		if machine.Region != "ap-northeast-1" {
			t.Errorf("plan region: want: ap-northeast-1 got: %s\n", machine.Region)
		}
	}

	fmt.Printf("result = %+v\n", result)
}

func TestTerraformStack(t *testing.T) {
	t.Parallel()
	username := "testuser13"
	userData, err := createUser(username, "ap-northeast-1")
	if err != nil {
		t.Fatal(err)
	}

	remote := userData.Remote

	args := &kloud.TerraformBootstrapRequest{
		PublicKeys: []string{userData.CredentialPublicKey},
	}

	_, err = remote.Tell("bootstrap", args)
	if err != nil {
		t.Error(err)
	}

	defer func() {
		// now destroy them all
		args.Destroy = true
		_, err = remote.Tell("bootstrap", args)
		if err != nil {
			t.Error(err)
		}
	}()

	applyArgs := &kloud.TerraformApplyRequest{
		StackId: userData.StackId,
	}

	resp, err := remote.Tell("apply", applyArgs)
	if err != nil {
		t.Error(err)
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		t.Fatal(err)
	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: userData.StackId,
			Type:    "apply",
		},
	})

	if err := listenEvent(eArgs, machinestate.Running, remote); err != nil {
		t.Error(err)
	}

	destroyArgs := &kloud.TerraformApplyRequest{
		StackId: userData.StackId,
		Destroy: true,
	}

	resp, err = remote.Tell("apply", destroyArgs)
	if err != nil {
		t.Fatal(err)
	}

	err = resp.Unmarshal(&result)
	if err != nil {
		t.Fatal(err)
	}

	eArgs = kloud.EventArgs([]kloud.EventArg{
		kloud.EventArg{
			EventId: userData.StackId,
			Type:    "apply",
		},
	})

	if err := listenEvent(eArgs, machinestate.Terminated, remote); err != nil {
		t.Error(err)
	}
}

func TestBuild(t *testing.T) {
	t.Parallel()
	username := "testuser"
	userData, err := createUser(username, "eu-west-1")
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Fatal(err)
	}

	// now try to ssh into the machine with temporary private key we created in
	// the beginning
	if err := checkSSHKey(userData.MachineIds[0].Hex(), userData.PrivateKey); err != nil {
		t.Error(err)
	}

	// invalid calls after build
	if err := build(userData.MachineIds[0].Hex(), userData.Remote); err == nil {
		t.Error("`build` method can not be called on `running` machines.")
	}

	if err := destroy(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Error(err)
	}
}

func checkSSHKey(id, privateKey string) error {
	log.Println("Checking deployed ssh key")
	// now try to ssh into the machine with temporary private key we created in
	// the beginning
	ctx := request.NewContext(context.Background(), &kite.Request{
		Username: "testuser",
	})
	ctx = eventer.NewContext(ctx, eventer.New(id))

	m, err := provider.Machine(ctx, id)
	if err != nil {
		return err
	}

	machine, ok := m.(*koding.Machine)
	if !ok {
		return fmt.Errorf("%v doesn't is a koding.Machine struct", m)
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

func TestStop(t *testing.T) {
	t.Parallel()
	username := "testuser2"
	userData, err := createUser(username, "eu-west-1")
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Fatal(err)
	}

	log.Println("Stopping machine")
	if err := stop(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Fatal(err)
	}

	// the following calls should give an error, if not there is a problem
	if err := build(userData.MachineIds[0].Hex(), userData.Remote); err == nil {
		t.Error("`build` method can not be called on `stopped` machines.")
	}

	if err := stop(userData.MachineIds[0].Hex(), userData.Remote); err == nil {
		t.Error("`stop` method can not be called on `stopped` machines.")
	}

	if err := destroy(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Error(err)
	}
}

func TestStart(t *testing.T) {
	t.Parallel()
	username := "testuser3"
	userData, err := createUser(username, "eu-west-1")
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Fatal(err)
	}

	log.Println("Stopping machine to start machine again")
	if err := stop(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Fatal(err)
	}

	log.Println("Starting machine")
	if err := start(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Errorf("`start` method can not be called on `stopped` machines: %s\n", err)
	}

	if err := start(userData.MachineIds[0].Hex(), userData.Remote); err == nil {
		t.Error("`start` method can not be called on `started` machines.")
	}

	if err := destroy(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Error(err)
	}
}

func TestSnapshot(t *testing.T) {
	t.Parallel()
	username := "testuser4"
	userData, err := createUser(username, "eu-west-1")
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Fatal(err)
	}

	log.Println("Creating snapshot")
	if err := createSnapshot(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Error(err)
	}

	log.Println("Retrieving snapshot id")
	snapshotId, err := getSnapshotId(userData.MachineIds[0].Hex(), userData.AccountId)
	if err != nil {
		t.Fatal(err)
	}

	log.Println("Deleting snapshot")
	if err := deleteSnapshot(userData.MachineIds[0].Hex(), snapshotId, userData.Remote); err != nil {
		t.Error(err)
	}

	// once deleted there shouldn't be any snapshot data in MongoDB
	log.Println("Checking snapshot data in MongoDB")
	if err := checkSnapshotMongoDB(snapshotId, userData.AccountId); err != errNoSnapshotFound {
		t.Error(err)
	}

	// also check AWS, be sure it's been deleted
	log.Println("Checking snapshot data in AWS")
	err = checkSnapshotAWS(userData.MachineIds[0].Hex(), snapshotId)
	if err != nil && !isSnapshotNotFoundError(err) {
		t.Error(err)
	}

	if err := destroy(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Error(err)
	}
}

func TestResize(t *testing.T) {
	t.Parallel()
	username := "testuser5"
	userData, err := createUser(username, "eu-west-1")
	if err != nil {
		t.Fatal(err)
	}

	if err := build(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Fatal(err)
	}

	defer func() {
		log.Println("Destroying machine")
		if err := destroy(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
			t.Error(err)
		}
	}()

	resize := func(storageWant int) {
		log.Printf("Resizing machine to %dGB\n", storageWant)
		err = provider.DB.Run("jMachines", func(c *mgo.Collection) error {
			return c.UpdateId(
				bson.ObjectIdHex(userData.MachineIds[0].Hex()),
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

		if err := resize(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
			t.Error(err)
		}

		storageGot, err := getAmazonStorageSize(userData.MachineIds[0].Hex())
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
}

// createUser creates a test user in jUsers and a single jMachine document.
func createUser(username, region string) (*singleUser, error) {
	privateKey, publicKey, err := sshutil.TemporaryKey()
	if err != nil {
		return nil, err
	}

	// cleanup old document
	provider.DB.Run("jUsers", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"username": username})
	})

	provider.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"profile.nickname": username})
	})

	// jAccounts
	accountId := bson.NewObjectId()
	account := &models.Account{
		Id: accountId,
		Profile: models.AccountProfile{
			Nickname: username,
		},
	}

	if err := provider.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Insert(&account)
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

	if err := provider.DB.Run("jUsers", func(c *mgo.Collection) error {
		return c.Insert(&user)
	}); err != nil {
		return nil, err
	}

	// jCredentials and jCredentialData
	credentialId := bson.NewObjectId()
	credPublicKey := randomID(24)
	credential := &models.Credential{
		Id:        credentialId,
		Provider:  "aws",
		PublicKey: credPublicKey,
		OriginId:  accountId,
	}

	if err := provider.DB.Run("jCredentials", func(c *mgo.Collection) error {
		return c.Insert(&credential)
	}); err != nil {
		return nil, err
	}

	credentialDataId := bson.NewObjectId()
	credentialData := &models.CredentialData{
		Id:        credentialDataId,
		PublicKey: credPublicKey,
		OriginId:  accountId,
		Meta: bson.M{
			"access_key": "",
			"secret_key": "",
			"region":     region,
		},
	}

	if err := provider.DB.Run("jCredentialDatas", func(c *mgo.Collection) error {
		return c.Insert(&credentialData)
	}); err != nil {
		return nil, err
	}

	relationshipId := bson.NewObjectId()
	relationship := &models.Relationship{
		Id:         relationshipId,
		TargetId:   credentialId,
		TargetName: "JCredential",
		SourceId:   accountId,
		SourceName: "JAccount",
		As:         "owner",
	}

	if err := provider.DB.Run("relationships", func(c *mgo.Collection) error {
		return c.Insert(&relationship)
	}); err != nil {
		return nil, err
	}

	// later we can add more users with "Owner:false" to test sharing capabilities
	users := []models.Permissions{
		{Id: userId, Sudo: true, Owner: true},
	}

	machineLabels := make([]string, machineCount)
	machineIds := make([]bson.ObjectId, machineCount)

	for i := 0; i < machineCount; i++ {
		label := "example." + strconv.Itoa(i)
		if machineCount == 1 {
			label = "example"
		}

		machineId := bson.NewObjectId()
		machine := &koding.Machine{
			Id:         machineId,
			Label:      label,
			Domain:     username + ".dev.koding.io",
			Credential: username,
			Provider:   "koding",
			CreatedAt:  time.Now().UTC(),
			Users:      users,
			Groups:     make([]models.Permissions, 0),
		}

		machine.Meta.Region = region
		machine.Meta.InstanceType = "t2.micro"
		machine.Meta.StorageSize = 3
		machine.Meta.AlwaysOn = false
		machine.Assignee.InProgress = false
		machine.Assignee.AssignedAt = time.Now().UTC()
		machine.Status.State = machinestate.NotInitialized.String()
		machine.Status.ModifiedAt = time.Now().UTC()

		machineLabels[i] = machine.Label
		machineIds[i] = machine.Id

		if err := provider.DB.Run("jMachines", func(c *mgo.Collection) error {
			return c.Insert(&machine)
		}); err != nil {
			return nil, err
		}
	}

	// jComputeStack and jStackTemplates
	stackTemplateId := bson.NewObjectId()
	stackTemplate := &models.StackTemplate{
		Id:          stackTemplateId,
		Credentials: []string{credPublicKey},
	}
	stackTemplate.Template.Content = fmt.Sprintf(terraformTemplate, machineCount)

	if err := provider.DB.Run("jStackTemplates", func(c *mgo.Collection) error {
		return c.Insert(&stackTemplate)
	}); err != nil {
		return nil, err
	}

	computeStackId := bson.NewObjectId()
	computeStack := &models.ComputeStack{
		Id:          computeStackId,
		BaseStackId: stackTemplateId,
		Machines:    machineIds,
	}

	if err := provider.DB.Run("jComputeStacks", func(c *mgo.Collection) error {
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

	return &singleUser{
		MachineIds:          machineIds,
		MachineLabels:       machineLabels,
		StackId:             computeStackId.Hex(),
		StackTemplateId:     stackTemplate.Id.Hex(),
		PrivateKey:          privateKey,
		PublicKey:           publicKey,
		AccountId:           accountId,
		CredentialId:        credentialId,
		CredentialPublicKey: credPublicKey,
		Remote:              remote,
	}, nil
}

func build(id string, remote *kite.Client) error {
	buildArgs := &args{
		MachineId: id,
		Provider:  "koding",
		TerraformContext: `
provider "aws" {
    access_key = "${var.access_key}"
    secret_key = "${var.secret_key}"
    region = "us-east-1"
}

resource "aws_instance" "example" {
    ami = "ami-d05e75b8"
    instance_type = "t2.micro"
}`,
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

	return listenEvent(eArgs, machinestate.Running, remote)

}

func destroy(id string, remote *kite.Client) error {
	destroyArgs := &args{
		MachineId: id,
		Provider:  "koding",
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

	return listenEvent(eArgs, machinestate.Terminated, remote)
}

func start(id string, remote *kite.Client) error {
	startArgs := &args{
		MachineId: id,
		Provider:  "koding",
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

	return listenEvent(eArgs, machinestate.Running, remote)
}

func stop(id string, remote *kite.Client) error {
	stopArgs := &args{
		MachineId: id,
		Provider:  "koding",
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

	return listenEvent(eArgs, machinestate.Stopped, remote)
}

func reinit(id string, remote *kite.Client) error {
	reinitArgs := &args{
		MachineId: id,
		Provider:  "koding",
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

	return listenEvent(eArgs, machinestate.Running, remote)
}

func restart(id string, remote *kite.Client) error {
	restartArgs := &args{
		MachineId: id,
		Provider:  "koding",
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

	return listenEvent(eArgs, machinestate.Running, remote)
}

func resize(id string, remote *kite.Client) error {
	resizeArgs := &args{
		MachineId: id,
		Provider:  "koding",
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

	return listenEvent(eArgs, machinestate.Running, remote)
}

func createSnapshot(id string, remote *kite.Client) error {
	createSnapshotArgs := &args{
		MachineId: id,
		Provider:  "koding",
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

	return listenEvent(eArgs, machinestate.Running, remote)
}

func deleteSnapshot(id, snapshotId string, remote *kite.Client) error {
	deleteSnapshotArgs := &args{
		MachineId:  id,
		SnapshotId: snapshotId,
		Provider:   "koding",
	}

	resp, err := remote.Tell("deleteSnapshot", deleteSnapshotArgs)
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
			EventId: deleteSnapshotArgs.MachineId,
			Type:    "deleteSnapshot",
		},
	})

	return listenEvent(eArgs, machinestate.Running, remote)
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

		fmt.Printf("e = %+v\n", e)

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

func kodingProvider() *koding.Provider {
	auth := aws.Auth{
		AccessKey: os.Getenv("KLOUD_ACCESSKEY"),
		SecretKey: os.Getenv("KLOUD_SECRETKEY"),
	}

	mongoURL := os.Getenv("KLOUD_MONGODB_URL")
	if mongoURL == "" {
		panic("KLOUD_MONGODB_URL is not set")
	}

	modelhelper.Initialize(mongoURL)
	db := modelhelper.Mongo

	return &koding.Provider{
		DB:         db,
		Log:        common.NewLogger("koding", true),
		DNSClient:  dnsclient.NewRoute53Client("dev.koding.io", auth),
		DNSStorage: dnsstorage.NewMongodbStorage(db),
		Kite:       kloudKite,
		EC2Clients: multiec2.New(auth, []string{
			"us-east-1",
			"ap-southeast-1",
			"us-west-2",
			"eu-west-1",
		}),
		Userdata: &userdata.Userdata{
			Keycreator: &keycreator.Key{
				KontrolURL:        conf.KontrolURL,
				KontrolPrivateKey: testkeys.Private,
				KontrolPublicKey:  testkeys.Public,
			},
			Bucket: userdata.NewBucket("koding-klient", "development/latest", auth),
		},
		PaymentFetcher: NewTestFetcher("hobbyist"),
		CheckerFetcher: NewTestChecker(),
	}
}

func kloudWithKodingProvider(p *koding.Provider) *kloud.Kloud {
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
	return kld
}

func getAmazonStorageSize(machineId string) (int, error) {
	ctx := request.NewContext(context.Background(), &kite.Request{
		Username: "testuser5",
	})
	ctx = eventer.NewContext(ctx, eventer.New(machineId))

	m, err := provider.Machine(ctx, machineId)
	if err != nil {
		return 0, err
	}

	machine, ok := m.(*koding.Machine)
	if !ok {
		return 0, fmt.Errorf("%v doesn't is a koding.Machine struct", m)
	}

	a := machine.Session.AWSClient

	instance, err := a.Instance()
	if err != nil {
		return 0, err
	}

	if len(instance.BlockDevices) == 0 {
		return 0, fmt.Errorf("fatal error: no block device available")
	}

	// we need in a lot of placages!
	oldVolumeId := instance.BlockDevices[0].VolumeId

	oldVolResp, err := machine.Session.AWSClient.Client.Volumes([]string{oldVolumeId}, ec2.NewFilter())
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
	var snapshot *models.Snapshot
	if err := provider.DB.Run("jSnapshots", func(c *mgo.Collection) error {
		return c.Find(bson.M{"originId": accountId, "machineId": bson.ObjectIdHex(machineId)}).One(&snapshot)
	}); err != nil {
		return "", err
	}

	return snapshot.SnapshotId, nil
}

func checkSnapshotAWS(machineId, snapshotId string) error {
	ctx := request.NewContext(context.Background(), &kite.Request{
		Username: "testuser4",
	})
	ctx = eventer.NewContext(ctx, eventer.New(machineId))

	m, err := provider.Machine(ctx, machineId)
	if err != nil {
		return err
	}

	machine, ok := m.(*koding.Machine)
	if !ok {
		return fmt.Errorf("%v doesn't is a koding.Machine struct", m)
	}

	_, err = machine.Session.AWSClient.Client.Snapshots([]string{snapshotId}, ec2.NewFilter())
	return err // nil means it exists
}

func checkSnapshotMongoDB(snapshotId string, accountId bson.ObjectId) error {
	var err error
	var count int

	err = provider.DB.Run("jSnapshots", func(c *mgo.Collection) error {
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

// randomID generates a random string of the given length
func randomID(length int) string {
	r := make([]byte, length*6/8)
	rand.Read(r)
	return base64.URLEncoding.EncodeToString(r)
}
