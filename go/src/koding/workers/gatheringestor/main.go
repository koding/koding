package main

import (
	"flag"
	"fmt"
	"koding/artifact"
	"koding/common"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"net"
	"net/http"
	"runtime"

	"github.com/PuerkitoBio/throttled"
	"github.com/PuerkitoBio/throttled/store"
	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/koding/redis"
)

var (
	WorkerName = "ingestor"
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

	stathandler := &GatherStat{log: log, dog: dogclient}
	errhandler := &GatherError{log: log, dog: dogclient}

	mux := http.NewServeMux()

	th := throttled.RateLimit(
		throttled.PerHour(10),
		&throttled.VaryBy{RemoteAddr: true, Path: false},
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
