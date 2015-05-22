package main

import (
	"flag"
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"log"
	"net/http"
	"runtime"

	"github.com/koding/logging"
	"github.com/ooyala/go-dogstatsd"
)

var (
	Name       = "ingestor"
	flagConfig = flag.String("c", "dev", "Configuration profile from file")
	Log        = logging.NewLogger(Name)

	DogClient *dogstatsd.Client
)

func initializeConf() *config.Config {
	runtime.GOMAXPROCS(runtime.NumCPU() - 1)

	flag.Parse()
	if *flagConfig == "" {
		log.Fatal("Please define config file with -c")
	}

	return config.MustConfig(*flagConfig)
}

func main() {
	conf := initializeConf()
	modelhelper.Initialize(conf.Mongo)

	var err error
	DogClient, err = dogstatsd.New("127.0.0.1:8125")
	if err != nil {
		log.Fatal(err)
	}

	http.HandleFunc("/", HomeHandler)
	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(Name))

	url := fmt.Sprintf(":%d", conf.GatherIngestor.Port)
	Log.Info("Starting gather ingestor on: %v", url)

	http.ListenAndServe(url, nil)
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
}
