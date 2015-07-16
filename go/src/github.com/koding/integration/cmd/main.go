package main

import (
	"fmt"
	"log"
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
	sf := services.NewServices()
	RegisterServices(sf, conf)

	h := integration.NewHandler(log, sf)

	mux := http.NewServeMux()
	mux.Handle("/{name}/{token}", h)
	mux.HandleFunc("/configure/{name}", h.Configure)

	log.Info("Integration server started")
	if err := http.ListenAndServe(conf.Addr, mux); err != nil {
		log.Fatal("Could not initialize server: %s", err)
	}
}

func RegisterServices(sf *services.Services, conf *Config) {
	service, err := RegisterGithubService(sf, conf)
	if err != nil {
		log.Fatal("Could not initialize service: %s", err)
	}

	sf.Register("github", service)
}

func RegisterGithubService(sf *services.Services, conf *Config) (services.Service, error) {
	gc := services.GithubConfig{}
	gc.PublicUrl = conf.PublicUrl
	gc.IntegrationUrl = conf.IntegrationAddr
	gc.Log = conf.Log

	return services.NewGithub(gc)
}
