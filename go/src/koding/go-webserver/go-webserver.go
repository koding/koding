package main

import (
	"flag"
	"fmt"
	"koding/artifact"
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"net/http"
	"runtime"

	"github.com/koding/logging"
)

var (
	Name              = "gowebserver"
	kodingTitle       = "Koding | Say goodbye to your localhost and write code in the cloud."
	kodingDescription = "Koding is a cloud-based development environment complete with free VMs, IDE & sudo enabled terminal where you can learn Ruby, Go, Java, NodeJS, PHP, C, C++, Perl, Python, etc."

	flagConfig = flag.String("c", "dev", "Configuration profile from file")
	Log        = logging.NewLogger(Name)

	kodingGroup *models.Group
	conf        *config.Config
)

func initialize() {
	runtime.GOMAXPROCS(runtime.NumCPU() - 1)

	flag.Parse()
	if *flagConfig == "" {
		Log.Critical("Please define config file with -c")
	}

	conf = config.MustConfig(*flagConfig)
	modelhelper.Initialize(conf.Mongo)

	var err error
	kodingGroup, err = modelhelper.GetGroup("koding")
	if err != nil {
		Log.Critical("Couldn't fetch `koding` group: %v", err)
		panic(err)
	}
}

func main() {
	initialize()

	http.HandleFunc("/", HomeHandler)
	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(Name))

	url := fmt.Sprintf(":%d", conf.Gowebserver.Port)
	Log.Info("Starting gowebserver on: %v", url)

	http.ListenAndServe(url, nil)
}
