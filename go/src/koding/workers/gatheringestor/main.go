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

	handler := &GatherIngestor{log: log, dog: dogclient}

	mux := http.NewServeMux()

	mux.Handle("/", handler)
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
