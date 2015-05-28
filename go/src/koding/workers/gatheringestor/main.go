package main

import (
	"flag"
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"net"
	"net/http"
	"runtime"

	"github.com/koding/logging"
	"github.com/koding/metrics"
)

var (
	WorkerName = "ingestor"
	flagConfig = flag.String("c", "dev", "Configuration profile from file")
)

func initializeConf() *config.Config {
	runtime.GOMAXPROCS(runtime.NumCPU() - 1)

	flag.Parse()
	if *flagConfig == "" {
		panic("Please define config file with -c")
	}

	return config.MustConfig(*flagConfig)
}

func main() {
	conf := initializeConf()
	modelhelper.Initialize(conf.Mongo)

	log := logging.NewLogger(WorkerName)

	dogclient, err := metrics.NewDogStatsD(WorkerName)
	if err != nil {
		log.Fatal(err.Error())
	}

	stathandler := &GatherStat{log: log, dog: dogclient}
	errhandler := &GatherError{log: log, dog: dogclient}

	mux := http.NewServeMux()

	mux.Handle("/stats", stathandler)
	mux.Handle("/errors", errhandler)

	mux.HandleFunc("/version", artifact.VersionHandler())
	mux.HandleFunc("/healthCheck", artifact.HealthCheckHandler(WorkerName))

	port := fmt.Sprintf("%v", conf.GatherIngestor.Port)
	listener, err := net.Listen("tcp", ":"+port)
	if err != nil {
		log.Fatal(err.Error())
	}

	log.Info("Listening on server: %s", port)

	if err = http.Serve(listener, mux); err != nil {
		log.Fatal(err.Error())
	}
}

func writeError(err error, w http.ResponseWriter) {
	w.WriteHeader(500)
	w.Write([]byte(err.Error()))
}
