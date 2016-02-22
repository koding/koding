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

	"gopkg.in/throttled/throttled.v2"
	"gopkg.in/throttled/throttled.v2/store/redigostore"

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

	redisStore, err := redigostore.New(redisConn.Pool(), WorkerName, 0)
	if err != nil {
		log.Fatal(err.Error()) // this is ok, if it doesn't connect it shouldn't start at all
	}

	quota := throttled.RateQuota{
		MaxRate:  throttled.PerHour(10),
		MaxBurst: 20,
	}

	rateLimiter, err := throttled.NewGCRARateLimiter(redisStore, quota)
	if err != nil {
		// we exit because this is code error and must be handled
		log.Fatal(err.Error())
	}

	httpRateLimiter := throttled.HTTPRateLimiter{
		RateLimiter: rateLimiter,
		VaryBy: &throttled.VaryBy{
			RemoteAddr: true,
			Path:       false,
		},
	}

	tStathandler := httpRateLimiter.RateLimit(stathandler)
	mux.Handle("/ingest", tStathandler)

	tErrHandler := httpRateLimiter.RateLimit(errhandler)
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
