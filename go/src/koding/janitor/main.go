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
	"github.com/koding/logging"
	"github.com/koding/runner"

	"github.com/koding/kite"
)

var (
	WorkerName    = "Janitor"
	WorkerVersion = "0.0.1"

	Log logging.Logger

	// List of warnings to iterate upon in a certain interval.
	Warnings = []*Warning{
		FirstEmail, SecondEmail, ThirdDeleteVM, FourthDeleteBlockedUserVm,
	}

	KiteClient *kite.Client

	// cron runs at utc, 4pm UTC is 8am PST
	DailyAtEightAM = "0 0 4 * * *"
)

func main() {
	r := initializeRunner()
	conf := config.MustRead(r.Conf.Path)
	port := conf.Janitor.Port

	go r.Listen()

	var err error
	kConf := r.Conf.Kloud

	KiteClient, err = initializeKiteClient(kConf.SecretKey, kConf.Address)
	if err != nil {
		Log.Fatal("Error initializing kite: %s", err.Error())
	}

	// c := cron.New()
	// c.AddFunc(DailyAtEightAM, func() {
	go func() {
		for _, warning := range Warnings {
			result := warning.Run()
			Log.Info(result.String())
		}
	}()
	// })

	// c.Start()

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
		r.Close()
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
		Log.Fatal("Error starting runner: %s", err.Error())
	}

	// appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize("localhost:27017/koding")

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
