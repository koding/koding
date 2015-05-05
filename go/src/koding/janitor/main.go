package main

import (
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"log"
	"net"
	"net/http"
	"socialapi/config"
	"time"

	kiteConfig "github.com/koding/kite/config"
	"github.com/koding/logging"
	"github.com/koding/runner"
	"github.com/robfig/cron"

	"github.com/koding/kite"
)

var (
	WorkerName    = "Janitor"
	WorkerVersion = "0.0.1"

	Log logging.Logger

	KiteClient *kite.Client

	// Warnings contains list of warnings to be iterated upon in a certain
	// interval.
	Warnings = []*Warning{
		ComebackEmail, VMDeletionEmail, DeleteInactiveUserVM, DeleteBlockedUserVM,
	}

	// DailyAtEightAM specifies interval; cron runs at utc, 3pm UTC is 8am PST
	// with daylight savings time
	DailyAtEightAM = "0 0 3 * * *"
)

func main() {
	var err error

	r := initializeRunner()

	conf := config.MustRead(r.Conf.Path)
	port := conf.Janitor.Port
	konf := conf.Kloud

	go r.Listen()

	KiteClient, err = initializeKiteClient(konf.SecretKey, konf.Address)
	if err != nil {
		Log.Fatal("Error initializing kite: %s", err.Error())
	}

	c := cron.New()
	c.AddFunc(DailyAtEightAM, func() {
		for _, w := range Warnings {

			// clone warning so local changes don't affect next run
			warning := *w

			result := warning.Run()
			Log.Info(result.String())
		}
	})

	c.Start()

	mux := http.NewServeMux()
	mux.HandleFunc("/version", artifact.VersionHandler())
	mux.HandleFunc("/healthCheck", artifact.HealthCheckHandler(WorkerName))

	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		Log.Fatal("Error opening tcp connection: %s", err.Error())
	}

	Log.Info("Listening on port: %s", port)

	r.ShutdownHandler = func() {
		listener.Close()
		KiteClient.Close()
		modelhelper.Close()
	}

	if err := http.Serve(listener, mux); err != nil {
		Log.Fatal("Error starting http server: %s", err.Error())
	}
}

func initializeRunner() *runner.Runner {
	r := runner.New(WorkerName)
	if err := r.Init(); err != nil {
		log.Fatal("Error starting runner: %s", err.Error())
	}

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	Log = r.Log

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
