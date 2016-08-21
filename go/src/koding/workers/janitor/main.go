package main

import (
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"log"
	"math/rand"
	"net"
	"net/http"
	"socialapi/config"
	"sync"
	"time"

	kiteConfig "github.com/koding/kite/config"
	"github.com/koding/logging"
	"github.com/koding/runner"
	"github.com/robfig/cron"

	"github.com/koding/kite"
)

const (
	WorkerName    = "janitor"
	WorkerVersion = "0.0.1"

	// DefaultRangeForQuery defines the range of interval for the queries.
	DefaultRangeForQuery = 3

	// DailyAtTwoPM specifies interval; cron runs at utc, 21 UTC is 2pm PST
	// with daylight savings time.
	DailyAtTwoPM = "0 0 21 * * *"
)

type janitor struct {
	runner     *runner.Runner
	log        logging.Logger
	kiteClient *kite.Client
}

var j = &janitor{}

func main() {
	j.initializeRunner()

	conf := config.MustRead(j.runner.Conf.Path)
	port := conf.Janitor.Port
	konf := conf.Kloud

	kloudSecretKey := conf.Janitor.SecretKey

	go j.runner.Listen()

	err := j.initializeKiteClient(kloudSecretKey, konf.Address)
	if err != nil {
		j.log.Fatal("Error initializing kite: %s", err.Error())
	}

	// warnings contains list of warnings to be iterated upon in a certain
	// interval.
	warnings := []*Warning{
		newDeleteInactiveUsersWarning(conf),
	}

	c := cron.New()
	c.AddFunc(DailyAtTwoPM, func() {
		var wg sync.WaitGroup

		for _, w := range warnings {
			wg.Add(1)

			// sleep random time to avoid all workers starting at the same time;
			// random time can be anywhere from 0 seconds to 1.38 hour.
			time.Sleep(time.Second * time.Duration(rand.Intn(5000)))

			go func(warning Warning) {
				defer wg.Done()

				result, err := warning.Run()
				if err != nil {
					j.log.Error(err.Error())
					return
				}

				j.log.Info(result.String())
			}(*w)
		}

		wg.Wait()
	})

	c.Start()

	mux := http.NewServeMux()
	mux.HandleFunc("/version", artifact.VersionHandler())
	mux.HandleFunc("/healthCheck", artifact.HealthCheckHandler(WorkerName))

	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		j.log.Fatal("Error opening tcp connection: %s", err.Error())
	}

	j.log.Info("Listening on port: %s", port)

	j.runner.ShutdownHandler = func() {
		listener.Close()
		j.runner.Kite.Close()
		modelhelper.Close()
	}

	if err := http.Serve(listener, mux); err != nil {
		j.log.Fatal("Error starting http server: %s", err.Error())
	}
}

func (j *janitor) initializeRunner() {
	r := runner.New(WorkerName)
	if err := r.Init(); err != nil {
		log.Fatal("Error starting runner: %s", err.Error())
	}

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	j.runner = r
	j.log = r.Log
}

func (j *janitor) initializeKiteClient(kloudKey, kloudAddr string) error {
	config, err := kiteConfig.Get()
	if err != nil {
		return err
	}

	r := j.runner

	// set skeleton config
	r.Kite.Config = config

	// create a new connection to the cloud
	kiteClient := r.Kite.NewClient(kloudAddr)
	kiteClient.Auth = &kite.Auth{Type: WorkerName, Key: kloudKey}
	kiteClient.Reconnect = true

	// dial the kloud address
	if err := kiteClient.DialTimeout(time.Second * 10); err != nil {
		return fmt.Errorf("%s. Is kloud running?", err.Error())
	}

	j.log.Debug("Connected to klient: %s", kloudAddr)

	j.kiteClient = kiteClient

	return nil
}
