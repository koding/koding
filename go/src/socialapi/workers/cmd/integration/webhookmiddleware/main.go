package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/integration"
	"github.com/koding/integration/services"
	"github.com/koding/runner"
)

const (
	Name = "WebhookMiddleware"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	defer r.Close()

	appConfig := config.MustRead(r.Conf.Path)
	workerConfig := appConfig.WebhookMiddleware
	mc := mux.NewConfig(Name, workerConfig.Host, workerConfig.Port)
	m := mux.New(mc, r.Log, r.Metrics)
	conf := &services.ServiceConfig{
		IntegrationAddr: appConfig.CustomDomain.Local + "/api/integration",
		PublicUrl:       appConfig.CustomDomain.Public + "/api/webhook",
		Log:             r.Log,
	}

	if r.Conf.Environment == "dev" || r.Conf.Environment == "test" {
		conf.IntegrationAddr =
			fmt.Sprintf("http://%s:%s", appConfig.Integration.Host,
				appConfig.Integration.Port)
	}

	serviceMap := services.NewServices()
	RegisterServices(serviceMap, appConfig, conf)

	h := integration.NewHandler(r.Log, serviceMap)

	addHandlers(m, h)

	go r.Listen()

	m.Listen()
	r.ShutdownHandler = m.Close

	r.Wait()
}

func addHandlers(m *mux.Mux, h *integration.Handler) {

	m.AddUnscopedHandler(
		handler.Request{
			Handler:  h.ServeHTTP,
			Type:     handler.PostRequest,
			Endpoint: "/{name}/{token}",
		},
	)

	m.AddUnscopedHandler(
		handler.Request{
			Handler:  h.Configure,
			Name:     "webhook-middleware-configure",
			Type:     handler.PostRequest,
			Endpoint: "/configure/{name}",
		},
	)
}

func RegisterServices(sf *services.Services, conf *config.Config, serviceConf *services.ServiceConfig) {
	github, err := RegisterGithubService(sf, conf, serviceConf)
	if err != nil {
		panic(err)
	}
	sf.Register("github", github)
}

func RegisterGithubService(sf *services.Services, conf *config.Config, serviceConf *services.ServiceConfig) (services.Service, error) {
	gc := services.GithubConfig{}
	gc.PublicUrl = serviceConf.PublicUrl
	gc.IntegrationUrl = serviceConf.IntegrationAddr
	gc.Log = serviceConf.Log
	gc.Secret = conf.Github.ClientSecret

	return services.NewGithub(gc)
}
