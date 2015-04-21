package main

import (
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"net"
	"net/http"
	"socialapi/config"
	"time"

	kiteConfig "github.com/koding/kite/config"
	"github.com/koding/runner"
	"github.com/robfig/cron"

	"github.com/koding/kite"
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
	r := initializeRunner()
	go r.Listen()

	port := r.Conf.Janitor.Port

	// initialize client to talk to kloud
	var err error

	kConf := r.Conf.Kloud
	KiteClient, err = initializeKiteClient(kConf.SecretKey, kConf.Address)
	if err != nil {
		Log.Fatal("Error initializing kite: %s", err.Error())
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
		Log.Fatal("Error opening tcp connection: %s", err.Error())
	}

	defer func() {
		r.Close()
		modelhelper.Close()
		KiteClient.Close()
		listener.Close()
	}()

	err = http.Serve(listener, mux)
	if err != nil {
		Log.Fatal("Error starting http server: %s", err.Error())
	}
}

func initializeRunner() *runner.Runner {
	r := runner.New(WorkerName)
	if err := r.Init(); err != nil {
		Log.Fatal("Error starting runner: %s", err.Error())
	}

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	return r
}

func initializeKiteClient(kloudKey, kloudAddr string) (*kite.Client, error) {
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
