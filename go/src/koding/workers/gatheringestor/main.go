package main

import (
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/tools/utils"
	"log"
	"net"
	"net/http"
	"socialapi/config"
	"time"

	kiteConfig "github.com/koding/kite/config"
	"github.com/koding/runner"

	"github.com/PuerkitoBio/throttled"
	"github.com/PuerkitoBio/throttled/store"
	"github.com/cenkalti/backoff"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/redis"
)

var (
	WorkerName       = "gatheringestor"
	WorkerVersion    = "0.0.1"
	GlobalDisableKey = "globalStopDisabled"
	ExemptUsersKey   = "exemptUsers"
	DefaultReason    = "abuse found in user VM"
	KodingProvider   = "koding"
	KloudTimeout     = 10 * time.Second
)

func main() {
	r := runner.New(WorkerName)
	if err := r.Init(); err != nil {
		panic(fmt.Sprintf("Error starting runner: %s", err))
	}

	go r.Listen()
	r.ShutdownHandler = func() { r.Kite.Close() }

	log := r.Log

	conf := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(conf.Mongo)

	modelhelper.Initialize(conf.Mongo)

	defer modelhelper.Close()

	redisConn, err := redis.NewRedisSession(&redis.RedisConf{
		Server: conf.Redis.URL,
		DB:     conf.Redis.DB,
	})
	if err != nil {
		log.Fatal(err.Error())
	}

	redisConn.SetPrefix(WorkerName)

	defer redisConn.Close()

	dogclient, err := metrics.NewDogStatsD(WorkerName)
	if err != nil {
		log.Fatal(err.Error())
	}

	var kiteClient *kite.Client
	if conf.GatherIngestor.ConnectToKloud {
		kiteClient = initializeKiteClient(conf)
	}

	stathandler := &GatherStat{log: log, dog: dogclient, kiteClient: kiteClient}
	errhandler := &GatherError{log: log, dog: dogclient}

	mux := http.NewServeMux()

	th := throttled.RateLimit(
		throttled.PerHour(50),
		&throttled.VaryBy{
			Path: false,
			Custom: func(r *http.Request) string {
				return utils.GetIpAddress(r)
			},
		},
		store.NewRedisStore(redisConn.Pool(), WorkerName, 0),
	)

	tStathandler := th.Throttle(stathandler)
	mux.Handle("/ingest", tStathandler)

	tErrHandler := th.Throttle(errhandler)
	mux.Handle("/errors", tErrHandler)

	mux.HandleFunc("/version", artifact.VersionHandler())
	mux.HandleFunc("/healthCheck", artifact.HealthCheckHandler(WorkerName))

	port := conf.GatherIngestor.Port

	log.Info("Listening on server: %s", port)

	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatal(err.Error())
	}

	defer listener.Close()

	if err = http.Serve(listener, mux); err != nil {
		log.Fatal(err.Error())
	}
}

func initializeKiteClient(conf *config.Config) *kite.Client {
	config, err := kiteConfig.Get()
	if err != nil {
		log.Fatal(err)
	}

	k := kite.New(WorkerName, WorkerVersion)
	k.Config = config

	kiteClient := k.NewClient(conf.GatherIngestor.KloudAddr)
	kiteClient.Auth = &kite.Auth{
		Type: WorkerName,
		Key:  conf.GatherIngestor.KloudSecretKey,
	}
	kiteClient.Reconnect = true

	operation := func() error {
		return kiteClient.DialTimeout(time.Second * 10)
	}

	err = backoff.Retry(operation, backoff.NewExponentialBackOff())
	if err != nil {
		log.Fatal("%s. Is kloud/kontrol running?", err)
	}

	return kiteClient
}

func write500Err(log logging.Logger, err error, w http.ResponseWriter) {
	writeErr(http.StatusInternalServerError, log, err, w)
}

func write404Err(log logging.Logger, err error, w http.ResponseWriter) {
	writeErr(http.StatusBadRequest, log, err, w)
}

func writeErr(code int, log logging.Logger, err error, w http.ResponseWriter) {
	log.Error(err.Error())

	w.WriteHeader(code)
	w.Write([]byte(err.Error()))
}
