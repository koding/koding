package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/helper"
	"time"

	kiteConfig "github.com/koding/kite/config"

	"github.com/koding/kite"
	"github.com/koding/kodingemail"
	"github.com/koding/multiconfig"
)

var (
	WorkerName    = "vmcleaner"
	WorkerVersion = "0.0.1"

	Log = helper.CreateLogger(WorkerName, false)

	Warnings   []*Warning
	controller *Controller
)

type Vmcleaner struct {
	Mongo             string `required:"true"`
	KloudSecretKey    string `required:"true"`
	KloudAddr         string `required:"true"`
	SendgridUsername  string `required:"true"`
	SendgridPassword  string `required:"true"`
	SendgridRecipient string
}

func main() {
	conf := initializeConf()
	modelhelper.Initialize(conf.Mongo)

	defer func() {
		modelhelper.Close()
	}()

	// initialize client to talk to kloud
	kiteClient := initializeKiteClient(conf.KloudSecretKey, conf.KloudAddr)

	// initialize client to send email
	email := initializeEmail(conf.SendgridUsername, conf.SendgridPassword)

	Warnings = initializeWarnings(kiteClient, email)

	for _, warning := range Warnings {
		result := warning.Run()
		fmt.Println(result)
	}
}

func initializeConf() *Vmcleaner {
	var conf = new(Vmcleaner)

	d := &multiconfig.DefaultLoader{
		Loader: multiconfig.MultiLoader(
			&multiconfig.EnvironmentLoader{Prefix: "KONFIG_VMCLEANER"},
		),
	}

	d.MustLoad(conf)

	return conf
}

func initializeKiteClient(kloudKey, kloudAddr string) *kite.Client {
	var err error

	// create new kite
	k := kite.New(WorkerName, WorkerVersion)
	config, err := kiteConfig.Get()
	if err != nil {
		Log.Fatal(err.Error())
	}

	// set skeleton config
	k.Config = config

	if k == nil {
		Log.Info("kite not initialized in runner. Pass '-kite-init'")
		return nil
	}

	// create a new connection to the cloud
	kiteClient := k.NewClient(kloudAddr)
	kiteClient.Auth = &kite.Auth{Type: "kloudctl", Key: kloudKey}

	// dial the kloud address
	if err := kiteClient.DialTimeout(time.Second * 10); err != nil {
		Log.Error("%s. Is kloud/kontrol running?", err.Error())
		return nil
	}

	Log.Debug("Connected to klient: %s", kloudAddr)

	return kiteClient
}

func initializeEmail(username, password string) kodingemail.Client {
	return kodingemail.NewSG(username, password)
}

func handleError(err error) {
	fmt.Println(err)
}
