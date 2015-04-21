package main

import (
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"net"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	kiteConfig "github.com/koding/kite/config"
	"github.com/koding/runner"
	"github.com/robfig/cron"

	"github.com/koding/kite"
	"github.com/koding/multiconfig"
)

var (
	WorkerName    = "Janitor"
	WorkerVersion = "0.0.1"

	Log = runner.CreateLogger(WorkerName, false)

	// List of warnings to iterate upon in a certain interval.
	Warnings = []*Warning{
		FirstEmail, SecondEmail, ThirdDeleteVM,
	}

	KiteClient *kite.Client

	// cron runs at utc, 4pm UTC is 8am PST
	DailyAtEightAM = "0 0 4 * * *"
)

type Janitor struct {
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

func initializeConf() *Janitor {
	var conf = new(Janitor)

	d := &multiconfig.DefaultLoader{
		Loader: multiconfig.MultiLoader(
			&multiconfig.EnvironmentLoader{Prefix: "KONFIG_JANITOR"},
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
	kiteClient.Reconnect = true

	// dial the kloud address
	if err := kiteClient.DialTimeout(time.Second * 10); err != nil {
		return nil, fmt.Errorf("%s. Is kloud running?", err.Error())
	}

	Log.Debug("Connected to klient: %s", kloudAddr)

	return kiteClient, nil
}
