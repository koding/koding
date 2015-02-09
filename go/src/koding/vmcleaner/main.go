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
	KiteClient = initializeKiteClient(conf.KloudSecretKey, conf.KloudAddr)

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

func initializeEmail(username, password, forceRecipient string) kodingemail.Client {
	return kodingemail.NewSG(username, password, forceRecipient)
}

func handleError(err error) {
	fmt.Println(err)
}
