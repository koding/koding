package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/helper"
	"time"

	kiteConfig "github.com/koding/kite/config"
	"github.com/robfig/cron"

	"github.com/koding/kite"
	"github.com/koding/kodingemail"
	"github.com/koding/multiconfig"
)

var (
	WorkerName    = "vmcleaner"
	WorkerVersion = "0.0.1"

	Log = helper.CreateLogger(WorkerName, false)

	// List of warnings to iterate upon in a certain interval.
	Warnings = []*Warning{
		FirstEmail, SecondEmail, ThirdEmail, FourthDeleteVM,
	}

	KiteClient *kite.Client
	Email      kodingemail.Client
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

	// initialize client to talk to kloud
	var err error

	KiteClient, err = initializeKiteClient(conf.KloudSecretKey, conf.KloudAddr)
	if err != nil {
		Log.Fatal(err.Error())
	}

	defer func() {
		modelhelper.Close()

		if KiteClient != nil {
			KiteClient.Close()
		}
	}()

	// initialize client to send email
	Email = initializeEmail(conf.SendgridUsername, conf.SendgridPassword,
		conf.SendgridRecipient)

	c := cron.New()

	c.AddFunc("@daily", func() {
		for _, warning := range Warnings {
			result := warning.Run()
			Log.Info(result.String())
		}
	})

	c.Start()
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

func initializeKiteClient(kloudKey, kloudAddr string) (*kite.Client, error) {
	var err error

	// create new kite
	k := kite.New(WorkerName, WorkerVersion)
	config, err := kiteConfig.Get()
	if err != nil {
		return nil, err
	}

	// set skeleton config
	k.Config = config

	// create a new connection to the cloud
	kiteClient := k.NewClient(kloudAddr)
	kiteClient.Auth = &kite.Auth{Type: "kloudctl", Key: kloudKey}

	// dial the kloud address
	if err := kiteClient.DialTimeout(time.Second * 10); err != nil {
		return nil, fmt.Errorf("%s. Is kloud running?", err.Error())
	}

	Log.Debug("Connected to klient: %s", kloudAddr)

	return kiteClient, nil
}

func initializeEmail(username, password, forceRecipient string) kodingemail.Client {
	return kodingemail.NewSG(username, password, forceRecipient)
}
