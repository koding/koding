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
)

var (
	Name       = "ingestor"
	flagConfig = flag.String("c", "dev", "Configuration profile from file")
	Log        = logging.NewLogger(Name)

	conf *config.Config
)

func initialize() {
	runtime.GOMAXPROCS(runtime.NumCPU() - 1)

	flag.Parse()
	if *flagConfig == "" {
		log.Fatal("Please define config file with -c")
	}

	conf = config.MustConfig(*flagConfig)
	modelhelper.Initialize(conf.Mongo)
}

func main() {
	initialize()

	http.HandleFunc("/", HomeHandler)
	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(Name))

	url := fmt.Sprintf(":%d", conf.GatherIngestor.Port)
	Log.Info("Starting gowebserver on: %v", url)

	http.ListenAndServe(url, nil)
}

func HomeHandler(w http.ResponseWriter, r *http.Request) {
}
