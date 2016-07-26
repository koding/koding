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
	proxyURL = "/api/webhook"
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

	conf.PublicURL = fmt.Sprintf("%s%s", conf.PublicURL, proxyURL)
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
	githubService, err := RegisterGithubService(sf, conf)
	if err != nil {
		log.Fatal("Could not initialize githubService: %s", err)
	}

	pivotalService, err := RegisterPivotalService(sf, conf)
	if err != nil {
		log.Fatal("Could not initialize Pivotal Service : %s", err)
	}

	pagerdutyService, err := RegisterPagerdutyService(sf, conf)
	if err != nil {
		log.Fatal("Could not initialize Pagerduty Service : %s", err)
	}

	sf.Register("github", githubService)
	sf.Register("pivotal", pivotalService)
	sf.Register("pagerduty", pagerdutyService)
}

func RegisterGithubService(sf *services.Services, conf *Config) (services.Service, error) {
	gc := services.GithubConfig{}
	gc.PublicURL = conf.PublicURL
	gc.IntegrationUrl = conf.IntegrationAddr
	gc.Log = conf.Log

	return services.NewGithub(gc)
}

func RegisterPivotalService(sf *services.Services, conf *Config) (services.Service, error) {
	pv := &services.PivotalConfig{
		ServerURL:      "",
		PublicURL:      conf.PublicURL,
		IntegrationURL: conf.IntegrationAddr,
	}

	return services.NewPivotal(pv, conf.Log)
}

func RegisterPagerdutyService(sf *services.Services, conf *Config) (services.Service, error) {
	pd := &services.PagerdutyConfig{
		PublicURL:      conf.PublicURL,
		IntegrationURL: conf.IntegrationAddr,
	}

	return services.NewPagerduty(pd, conf.Log)
}
