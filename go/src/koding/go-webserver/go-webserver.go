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
	kodingTitle       = "Koding | Say goodbye to your localhost and code in the cloud."
	kodingDescription = "Koding is a cloud-based development environment complete with free VMs, IDE & sudo enabled terminal where you can learn Ruby, Go, Java, NodeJS, PHP, C, C++, Perl, Python, etc."
	kodingShareUrl    = "https://koding.com"
	kodingGpImage     = "koding.com/a/site.landing/images/share.g+.jpg"
	kodingFbImage     = "koding.com/a/site.landing/images/share.fb.jpg"
	kodingTwImage     = "koding.com/a/site.landing/images/share.tw.jpg"

	flagConfig = flag.String("c", "dev", "Configuration profile from file")
	Log        = logging.NewLogger(Name)

	kodingGroup *models.Group
	conf        *config.Config
)

func initialize() {
	runtime.GOMAXPROCS(runtime.NumCPU())

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

	version := conf.Version
	addVersionToShareUrls(version)

	http.HandleFunc("/", HomeHandler)
	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(Name))

	url := fmt.Sprintf(":%d", conf.Gowebserver.Port)
	Log.Info("Starting gowebserver on: %v", url)

	http.ListenAndServe(url, nil)
}

func addVersionToShareUrls(version string) {
	kodingGpImage = fmt.Sprintf("%s?%s", kodingGpImage, version)
	kodingFbImage = fmt.Sprintf("%s?%s", kodingFbImage, version)
	kodingTwImage = fmt.Sprintf("%s?%s", kodingTwImage, version)
}
