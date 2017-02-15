// +build ignore

package main

/* HOW TO RUN THE TEST

Be sure you have a running ngrok instance. This is needed so klient can connect
to our kontrol. Run it with (ensure you use v1 version - https://ngrok.com/download/1):

	$ ngrok -authtoken="CMY-UsZMWdx586A3tA0U" -subdomain="kloud-test" 4099

If the above fails with message like:

    Server failed to allocate tunnel: The tunnel http://kloud-test.ngrok.com is already registered.

You may want to use your own tunnel. Register with https://ngrok.com/, download v2
and extract the executable as ngrok2 into your $PATH. Authenticate token and start
tunnel with:

	$ ngrok2 http 4099

The UI will display tunnel address which you want to export via KLOUD_KONTROL_URL env var
prior to running kloud tests, e.g.:

	$ export KLOUD_KONTROL_URL=http://80518f26.ngrok.io/kite

The most handy way for setting up the kloud kontrol url is to query for the
tunnel address via the ngrok api, e.g.:

	$ export KLOUD_KONTROL_URL="$(curl -sS localhost:4040/api/tunnels | jq -r .tunnels[0].public_url)/kite"

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
	go tool pprof --pdf kloud.test	kloud_cpu.prof > kloud_cpu.pdf
*/

import (
	"bytes"
	"crypto/rand"
	"encoding/base64"
	"errors"
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"os/exec"
	"path/filepath"
	"strconv"
	"testing"
	"time"

	"gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kontrol"
	"github.com/koding/kite/protocol"
	"github.com/koding/kite/testkeys"
	"github.com/koding/kite/testutil"
	"github.com/koding/logging"
	"golang.org/x/net/context"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/keycreator"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/provider/softlayer"
	"koding/kites/kloud/sshutil"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/userdata"
	"koding/kites/terraformer"

	"github.com/aws/aws-sdk-go/aws/credentials"
)

var (
	kloudKite   *kite.Kite
	kld         *kloud.Kloud
	conf        *config.Config
	awsProvider *awsprovider.Provider
	slProvider  *softlayer.Provider

	defaultRegion       = "eu-west-1"
	defaultDatacenter   = "sjc01"
	defaultInstanceType = "t2.nano"

	team = &Client{
		Provider:     "aws",
		Region:       "", // overwrite with KLOUD_TEST_REGION
		InstanceType: "", // overwrite with KLOUD_TEST_INSTANCE_TYPE
	}

	errNoSnapshotFound = errors.New("No snapshot found for the given user")

	machineCount      = 1
	terraformTemplate = `{
    "variable": {
        "username": {
            "default": "fatih"
        }
    },
    "provider": {
        "aws": {
            "access_key": "${var.aws_access_key}",
            "secret_key": "${var.aws_secret_key}"
        }
    },
    "resource": {
        "aws_instance": {
            "example": {
                "count": %d,
                "instance_type": "%s",
                "user_data": "sudo apt-get install sl -y\ntouch /tmp/${var.username}.txt"
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

func init() {
	if s := os.Getenv("KLOUD_TEST_REGION"); s != "" {
		team.Region = s
	}
	if s := os.Getenv("KLOUD_TEST_INSTANCE_TYPE"); s != "" {
		team.InstanceType = s
	}
	repoPath, err := currentRepoPath()
	if err != nil {
		log.Fatal("currentRepoPath error:", err)
	}

	conf = config.New()
	conf.Username = "koding"

	conf.KontrolURL = os.Getenv("KLOUD_KONTROL_URL")
	if conf.KontrolURL == "" {
		conf.KontrolURL = "http://localhost:4099/kite"
	}

	conf.KontrolKey = testkeys.Public
	conf.KontrolUser = "koding"
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
	_, err = kloudKite.Register(kiteURL)
	if err != nil {
		log.Fatal("kloud ", err.Error())
	}

	awsProvider, slProvider = providers()

	// Add Kloud handlers
	kld := kloudWithProviders(awsProvider, slProvider)
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

	t, err := terraformer.New(tConf, logging.NewCustom("terraformer", false))
	if err != nil {
		log.Fatal("terraformer ", err.Error())
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

	log.Println("=== Test instances are up and ready!. Executing now the tests... ===")

	// hashicorp.terraform outputs many logs, discard them
	log.SetOutput(ioutil.Discard)
}

func TestTerraformAuthenticate(t *testing.T) {
	username := "testuser12"
	groupname := "koding"
	userData, err := team.CreateUser(username, groupname)
	if err != nil {
		t.Fatal(err)
	}

	remote := userData.Remote

	args := &kloud.AuthenticateRequest{
		Identifiers: userData.Identifiers,
		GroupName:   groupname,
	}

	_, err = remote.Tell("authenticate", args)
	if err != nil {
		t.Error(err)
	}
}

func TestTerraformBootstrap(t *testing.T) {
	username := "testuser11"
	groupname := "koding"
	userData, err := team.CreateUser(username, groupname)
	if err != nil {
		t.Fatal(err)
	}

	remote := userData.Remote

	args := &kloud.BootstrapRequest{
		Identifiers: userData.Identifiers,
		GroupName:   groupname,
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

func TestTerraformStack(t *testing.T) {
	t.Parallel()
	username := "testuser"
	groupname := "koding"
	userData, err := team.CreateUser(username, groupname)
	if err != nil {
		t.Fatal(err)
	}

	remote := userData.Remote

	args := &kloud.BootstrapRequest{
		Identifiers: userData.Identifiers,
		GroupName:   groupname,
	}

	_, err = remote.Tell("bootstrap", args)
	if err != nil {
		t.Fatal(err)
	}

	defer func() {
		// now destroy them all
		args.Destroy = true
		_, err = remote.Tell("bootstrap", args)
		if err != nil {
			t.Error(err)
		}
	}()

	planArgs := &kloud.PlanRequest{
		StackTemplateID: userData.StackTemplateId,
		GroupName:       groupname,
	}

	resp, err := remote.Tell("plan", planArgs)
	if err != nil {
		t.Fatal(err)
	}

	var planResult *stackplan.Machines
	if err := resp.Unmarshal(&planResult); err != nil {
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

	for _, machine := range planResult.Machines {
		if !inLabels(machine.Label) {
			t.Errorf("plan label: have: %+v got: %s\n", userData.MachineLabels, machine.Label)
		}

		if machine.Region != team.region() {
			t.Errorf("plan region: want: %s got: %s\n", team.region(), machine.Region)
		}
	}

	applyArgs := &kloud.ApplyRequest{
		StackID:   userData.StackId,
		GroupName: groupname,
	}

	resp, err = remote.Tell("apply", applyArgs)
	if err != nil {
		t.Fatal(err)
	}

	var result kloud.ControlResult
	err = resp.Unmarshal(&result)
	if err != nil {
		t.Fatal(err)
	}

	eArgs := kloud.EventArgs([]kloud.EventArg{
		{
			EventId: userData.StackId,
			Type:    "apply",
		},
	})

	if err := listenEvent(eArgs, machinestate.Running, remote); err != nil {
		t.Error(err)
	}

	fmt.Printf("===> STARTED to start/stop the machine with id: %s\n", userData.MachineIds[0].Hex())

	if err := team.Stop(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Error(err)
	}

	if err := team.Start(userData.MachineIds[0].Hex(), userData.Remote); err != nil {
		t.Error(err)
	}

	destroyArgs := &kloud.ApplyRequest{
		StackID:   userData.StackId,
		Destroy:   true,
		GroupName: groupname,
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
		{
			EventId: userData.StackId,
			Type:    "apply",
		},
	})

	if err := listenEvent(eArgs, machinestate.Terminated, remote); err != nil {
		t.Error(err)
	}
}

// CreateUser creates a test user in jUsers and a single jMachine document.
func (c *Client) CreateUser(username, groupname string) (*singleUser, error) {
	privateKey, publicKey, err := sshutil.TemporaryKey()
	if err != nil {
		return nil, err
	}

	// cleanup old document
	awsProvider.DB.Run("jUsers", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"username": username})
	})

	awsProvider.DB.Run("jAccounts", func(c *mgo.Collection) error {
		return c.Remove(bson.M{"profile.nickname": username})
	})

	awsProvider.DB.Run("jGroups", func(c *mgo.Collection) error {
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

	if err := awsProvider.DB.Run("jAccounts", func(c *mgo.Collection) error {
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

	if err := awsProvider.DB.Run("jGroups", func(c *mgo.Collection) error {
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

	if err := awsProvider.DB.Run("relationships", func(c *mgo.Collection) error {
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
		Name:          username, // bson equivalent is username
		Password:      "somerandomnumbers",
		Status:        "confirmed",
		SshKeys: []struct {
			Title string `bson:"title"`
			Key   string `bson:"key"`
		}{
			{Key: publicKey},
		},
	}

	if err := awsProvider.DB.Run("jUsers", func(c *mgo.Collection) error {
		return c.Insert(&user)
	}); err != nil {
		return nil, err
	}

	// jCredentials and jCredentialData
	credentials := map[string][]string{}

	addCredential := func(credProvider string, data map[string]interface{}) error {
		credentialId := bson.NewObjectId()
		identifier := randomID(24)
		credential := &models.Credential{
			Id:         credentialId,
			Provider:   credProvider,
			Identifier: identifier,
			OriginId:   accountId,
		}

		if err := awsProvider.DB.Run("jCredentials", func(c *mgo.Collection) error {
			return c.Insert(&credential)
		}); err != nil {
			return err
		}

		credentialDataId := bson.NewObjectId()
		credentialData := &models.CredentialData{
			Id:         credentialDataId,
			Identifier: identifier,
			OriginId:   accountId,
			Meta:       data,
		}

		if err := awsProvider.DB.Run("jCredentialDatas", func(c *mgo.Collection) error {
			return c.Insert(&credentialData)
		}); err != nil {
			return err
		}

		credRelationship := &models.Relationship{
			Id:         bson.NewObjectId(),
			TargetId:   credentialId,
			TargetName: "JCredential",
			SourceId:   accountId,
			SourceName: "JAccount",
			As:         "owner",
		}

		if err := awsProvider.DB.Run("relationships", func(c *mgo.Collection) error {
			return c.Insert(&credRelationship)
		}); err != nil {
			return err
		}

		credentials[credProvider] = []string{identifier}
		return nil
	}

	err = addCredential("aws", map[string]interface{}{
		"access_key": os.Getenv("KLOUD_TESTACCOUNT_ACCESSKEY"),
		"secret_key": os.Getenv("KLOUD_TESTACCOUNT_SECRETKEY"),
		"region":     c.region(),
	})
	if err != nil {
		return nil, err
	}

	err = addCredential("softlayer", map[string]interface{}{
		"username": os.Getenv("KLOUD_TESTACCOUNT_SLUSERNAME"),
		"api_key":  os.Getenv("KLOUD_TESTACCOUNT_SLAPIKEY"),
	})
	if err != nil {
		return nil, err
	}

	// jComputeStack and jStackTemplates
	stackTemplateId := bson.NewObjectId()
	stackTemplate := &models.StackTemplate{
		Id:          stackTemplateId,
		Credentials: credentials,
	}
	stackTemplate.Template.Content = fmt.Sprintf(terraformTemplate, machineCount, c.instanceType())

	if err := awsProvider.DB.Run("jStackTemplates", func(c *mgo.Collection) error {
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
		label := "example." + strconv.Itoa(i)
		if machineCount == 1 {
			label = "example"
		}

		machineId := bson.NewObjectId()
		machine := &models.Machine{
			ObjectId:  machineId,
			Label:     label,
			Domain:    username + ".dev.koding.io",
			Provider:  c.Provider,
			CreatedAt: time.Now().UTC(),
			Users:     users,
			Meta:      make(bson.M, 0),
			Groups:    make([]models.MachineGroup, 0),
		}

		switch c.Provider {
		case "koding":
			machine.Credential = username
		default:
			// aws, softlayer
			machine.Credential = credentials[c.Provider][0]
		}

		c.updateMeta(machine.Meta)
		machine.Meta["storage_size"] = 3
		machine.Meta["alwaysOn"] = false
		machine.Assignee.InProgress = false
		machine.Assignee.AssignedAt = time.Now().UTC()
		machine.Status.State = machinestate.NotInitialized.String()
		machine.Status.ModifiedAt = time.Now().UTC()

		machineLabels[i] = machine.Label
		machineIds[i] = machine.ObjectId

		if err := awsProvider.DB.Run("jMachines", func(c *mgo.Collection) error {
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

	if err := awsProvider.DB.Run("jComputeStacks", func(c *mgo.Collection) error {
		return c.Insert(&computeStack)
	}); err != nil {
		return nil, err
	}

	userKite := kite.New("user", "0.0.1")
	confCopy := conf.Copy()
	confCopy.KiteKey = testutil.NewKiteKeyUsername(username).Raw
	confCopy.Username = username
	userKite.Config = confCopy

	kloudQuery := &protocol.KontrolQuery{
		Username:    "testuser",
		Environment: confCopy.Environment,
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
	for _, i := range credentials {
		identifiers = append(identifiers, i...)
	}

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

type Client struct {
	Provider     string
	Region       string
	InstanceType string
}

func (c *Client) region() string {
	if c.Region != "" {
		return c.Region
	}
	switch c.Provider {
	case "softlayer":
		return defaultDatacenter
	default:
		return defaultRegion
	}
}

func (c *Client) instanceType() string {
	if c.InstanceType != "" {
		return c.InstanceType
	}
	return defaultInstanceType
}

func (c *Client) updateMeta(m bson.M) {
	switch c.Provider {
	case "softlayer":
		m["datacenter"] = c.region()
	default:
		m["region"] = c.region()
		m["instance_type"] = c.instanceType()
	}
}

func (c *Client) Build(id string, remote *kite.Client) error {
	buildArgs := &args{
		MachineId: id,
		Provider:  c.Provider,
		TerraformContext: fmt.Sprintf(`
provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "%s"
}

resource "aws_instance" "example" {
    ami = "ami-d05e75b8"
    instance_type = "%s"
}`, c.region(), c.instanceType()),
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
		{
			EventId: buildArgs.MachineId,
			Type:    "build",
		},
	})

	return listenEvent(eArgs, machinestate.Running, remote)

}

func (c *Client) Destroy(id string, remote *kite.Client) error {
	destroyArgs := &args{
		MachineId: id,
		Provider:  c.Provider,
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
		{
			EventId: destroyArgs.MachineId,
			Type:    "destroy",
		},
	})

	return listenEvent(eArgs, machinestate.Terminated, remote)
}

func (c *Client) Start(id string, remote *kite.Client) error {
	startArgs := &args{
		MachineId: id,
		Provider:  c.Provider,
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
		{
			EventId: startArgs.MachineId,
			Type:    "start",
		},
	})

	return listenEvent(eArgs, machinestate.Running, remote)
}

func (c *Client) Stop(id string, remote *kite.Client) error {
	stopArgs := &args{
		MachineId: id,
		Provider:  c.Provider,
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
		{
			EventId: stopArgs.MachineId,
			Type:    "stop",
		},
	})

	return listenEvent(eArgs, machinestate.Stopped, remote)
}

func (c *Client) Reinit(id string, remote *kite.Client) error {
	reinitArgs := &args{
		MachineId: id,
		Provider:  c.Provider,
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
		{
			EventId: reinitArgs.MachineId,
			Type:    "reinit",
		},
	})

	return listenEvent(eArgs, machinestate.Running, remote)
}

func (c *Client) Restart(id string, remote *kite.Client) error {
	restartArgs := &args{
		MachineId: id,
		Provider:  c.Provider,
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
		{
			EventId: restartArgs.MachineId,
			Type:    "restart",
		},
	})

	return listenEvent(eArgs, machinestate.Running, remote)
}

func (c *Client) Resize(id string, remote *kite.Client) error {
	resizeArgs := &args{
		MachineId: id,
		Provider:  c.Provider,
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
		{
			EventId: resizeArgs.MachineId,
			Type:    "resize",
		},
	})

	return listenEvent(eArgs, machinestate.Running, remote)
}

func (c *Client) CreateSnapshot(id string, remote *kite.Client) error {
	createSnapshotArgs := &args{
		MachineId: id,
		Provider:  c.Provider,
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
		{
			EventId: createSnapshotArgs.MachineId,
			Type:    "createSnapshot",
		},
	})

	return listenEvent(eArgs, machinestate.Running, remote)
}

func (c *Client) DeleteSnapshot(id, snapshotId string, remote *kite.Client) error {
	deleteSnapshotArgs := &args{
		MachineId:  id,
		SnapshotId: snapshotId,
		Provider:   c.Provider,
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
		{
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

func providers() (*awsprovider.Provider, *softlayer.Provider) {
	c := credentials.NewStaticCredentials(os.Getenv("KLOUD_ACCESSKEY"), os.Getenv("KLOUD_SECRETKEY"), "")

	mongoURL := os.Getenv("KLOUD_MONGODB_URL")
	if mongoURL == "" {
		panic("KLOUD_MONGODB_URL is not set")
	}

	modelhelper.Initialize(mongoURL)
	db := modelhelper.Mongo

	dnsOpts := &dnsclient.Options{
		Creds:      c,
		HostedZone: "dev.koding.io",
		Log:        logging.NewCustom("dns", true),
	}

	dnsInstance, err := dnsclient.NewRoute53Client(dnsOpts)
	if err != nil {
		panic(err)
	}

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
		Log:         logging.NewCustom("koding", true),
	}

	_, err := amazon.NewClients(opts)
	if err != nil {
		panic(err)
	}

	slclient := sl.NewSoftlayer(
		os.Getenv("KLOUD_TESTACCOUNT_SLUSERNAME"),
		os.Getenv("KLOUD_TESTACCOUNT_SLAPIKEY"),
	)

	awsp := &awsprovider.Provider{
		DB:         db,
		Log:        logging.NewCustom("kloud-aws", true),
		DNSClient:  dnsInstance,
		DNSStorage: dnsStorage,
		Kite:       kloudKite,
		Userdata:   usd,
	}

	slp := &softlayer.Provider{
		DB:         db,
		Log:        logging.NewCustom("kloud-softlayer", true),
		DNSClient:  dnsInstance,
		DNSStorage: dnsStorage,
		SLClient:   slclient,
		Kite:       kloudKite,
		Userdata:   usd,
	}

	return kdp, awsp, slp
}

func kloudWithProviders(a *awsprovider.Provider, s *softlayer.Provider) *kloud.Kloud {
	kloudLogger := logging.NewCustom("kloud", true)
	sess := &session.Session{
		DB:         a.DB,
		Kite:       a.Kite,
		DNSClient:  a.DNSClient,
		DNSStorage: a.DNSStorage,
		AWSClients: a.EC2Clients,
		Userdata:   a.Userdata,
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

// randomID generates a random string of the given length
func randomID(length int) string {
	r := make([]byte, length*6/8)
	rand.Read(r)
	return base64.URLEncoding.EncodeToString(r)
}

// currentRepoPath returns the root path of current koding git repository
func currentRepoPath() (string, error) {
	p, err := exec.Command("git", "rev-parse", "--show-toplevel").Output()
	if err != nil {
		return "", err
	}
	return string(bytes.TrimSpace(p)), nil
}
