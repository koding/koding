package main

import (
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"net"
	"net/http"
	"os"
	"os/signal"
	"socialapi/workers/helper"
	"syscall"
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

	// cron runs at utc, 4pm UTC is 8am PST
	DailyAtEightAM = "0 0 4 * * *"
)

type Vmcleaner struct {
	Port              string `required:"true"`
	Mongo             string `required:"true"`
	KloudSecretKey    string `required:"true"`
	KloudAddr         string `required:"true"`
	SendgridUsername  string `required:"true"`
	SendgridPassword  string `required:"true"`
	SendgridRecipient string
}

func main() {
	conf := initializeConf()
	port := conf.Port

	modelhelper.Initialize(conf.Mongo)

	// initialize client to talk to kloud
	var err error

	KiteClient, err = initializeKiteClient(conf.KloudSecretKey, conf.KloudAddr)
	if err != nil {
		Log.Fatal(err.Error())
	}

	// initialize client to send email
	Email = initializeEmail(conf.SendgridUsername, conf.SendgridPassword,
		conf.SendgridRecipient)

	c := cron.New()

	c.AddFunc(DailyAtEightAM, func() {
		for _, warning := range Warnings {
			result := warning.Run()
			Log.Info(result.String())
		}
	})

	c.Start()

	mux := http.NewServeMux()

	mux.HandleFunc("/version", artifact.VersionHandler())
	mux.HandleFunc("/healthCheck", artifact.HealthCheckHandler(WorkerName))

	Log.Info("Listening on port: %s", port)

	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		Log.Fatal(err.Error())
	}

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)

		for {
			signal := <-signals
			switch signal {
			case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP, syscall.SIGKILL:
				modelhelper.Close()
				listener.Close()

				if KiteClient != nil {
					KiteClient.Close()
				}

				os.Exit(0)
			}
		}
	}()

	err = http.Serve(listener, mux)
	if err != nil {
		Log.Fatal(err.Error())
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
