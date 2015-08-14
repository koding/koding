package main

import (
	"flag"
	"fmt"
	"koding/artifact"
	"koding/common"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"koding/tools/utils"
	"log"
	"net"
	"net/http"
	"runtime"
	"time"

	kiteConfig "github.com/koding/kite/config"

	"github.com/PuerkitoBio/throttled"
	"github.com/PuerkitoBio/throttled/store"
	"github.com/cenkalti/backoff"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/redis"
)

var (
	WorkerName    = "gatheringestor"
	WorkerVersion = "0.0.1"

	flagConfig = flag.String("c", "dev", "Configuration profile from file")
)

func initializeConf() *config.Config {
	runtime.GOMAXPROCS(runtime.NumCPU())

	flag.Parse()
	if *flagConfig == "" {
		panic("Please define config file with -c")
	}

	return config.MustConfig(*flagConfig)
}

func main() {
	log := common.CreateLogger(WorkerName, false)

	conf := initializeConf()
	modelhelper.Initialize(conf.Mongo)

	defer modelhelper.Close()

	redisConn, err := redis.NewRedisSession(&redis.RedisConf{Server: conf.Redis})
	if err != nil {
		log.Fatal(err.Error())
	}

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

	port := fmt.Sprintf("%v", conf.GatherIngestor.Port)

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
	var err error

	// create new kite
	k := kite.New(WorkerName, WorkerVersion)
	config, err := kiteConfig.Get()
	if err != nil {
		log.Fatal(err)
	}

	// set skeleton config
	k.Config = config

	// create a new connection to the cloud
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
