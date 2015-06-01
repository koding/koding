package main

import (
	"flag"
	"fmt"
	"koding/artifact"
	"koding/db/mongodb/modelhelper"
	"koding/tools/config"
	"net/http"
	"runtime"

	"github.com/koding/logging"
)

var (
	Name            = "tokenizer"
	IterableAuthKey = "aaaa"

	flagConfig = flag.String("c", "dev", "Configuration profile from file")
	Log        = logging.NewLogger(Name)

	Jwttoken string
)

func initialize() *config.Config {
	runtime.GOMAXPROCS(runtime.NumCPU() - 1)

	conf := config.MustConfig(*flagConfig)
	modelhelper.Initialize(conf.Mongo)

	Jwttoken = conf.Jwttoken

	flag.Parse()
	if *flagConfig == "" {
		panic("Please define config FilesUpdateCall with -c")
	}

	return conf
}

func main() {
	conf := initialize()

	http.HandleFunc("/-/mail/get", TokenGetHandler)
	http.HandleFunc("/-/mail/confirm", TokenConfirmHandler)

	http.HandleFunc("/version", artifact.VersionHandler())
	http.HandleFunc("/healthCheck", artifact.HealthCheckHandler(Name))

	url := fmt.Sprintf(":%d", conf.Tokenizer.Port)
	Log.Info("Starting tokenizer on: %v", url)

	http.ListenAndServe(url, nil)
}
