package main

import (
	"fmt"
	"net/http"

	"github.com/koding/integration"
	"github.com/koding/integration/services"
	"github.com/koding/logging"
	"github.com/koding/multiconfig"
)

const (
	proxyUrl = "/api/webhook"
)

type Config struct {
	Addr string `env:"WEBHOOK_MIDDLEWARE_ADDR" default:"localhost:1234"`
	services.ServiceConfig
}

func main() {
	m := multiconfig.New()
	conf := new(Config)
	m.MustLoad(conf)

	log := logging.NewLogger("webhook")

	conf.PublicUrl = fmt.Sprintf("%s%s", conf.PublicUrl, proxyUrl)
	h := integration.NewHandler(log, &conf.ServiceConfig)
	mux := http.NewServeMux()
	mux.Handle("/push/{name}/{token}", h)
	mux.HandleFunc("/configure/{name}", h.Configure)

	log.Info("Integration server started")
	if err := http.ListenAndServe(conf.Addr, mux); err != nil {
		log.Fatal("Could not initialize server: %s", err)
	}
}
