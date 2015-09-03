package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/integration"
	"github.com/koding/integration/helpers"
	"github.com/koding/integration/services"
	"github.com/koding/logging"
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
		PublicURL:       appConfig.CustomDomain.Public + "/api/webhook",
		Log:             r.Log,
	}

	if r.Conf.Environment == "dev" || r.Conf.Environment == "test" {
		conf.IntegrationAddr =
			fmt.Sprintf("http://%s:%s", appConfig.Integration.Host,
				appConfig.Integration.Port)
	}

	// init SQS fallback queue
	systemName := fmt.Sprintf("%s-%s", Name, r.Conf.Environment)
	if err := r.InitSQS(systemName); err != nil {
		r.Log.Warning("Could not init sqs, fallback queue will be disabled: %s", err)
	} else {
		// when we encounter with an issue during webhook message push operation
		// message must be queued in SQS
		helpers.FallbackFn = r.SQS.Push

		go r.ListenSQS(helpers.FallbackHandler)
	}

	serviceMap := services.NewServices()
	RegisterServices(serviceMap, appConfig, conf, r.Log)

	h := integration.NewHandler(r.Log, serviceMap)

	addHandlers(m, h)

	go r.Listen()

	m.Listen()
	defer m.Close()

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

func RegisterServices(sf *services.Services, conf *config.Config, serviceConf *services.ServiceConfig, log logging.Logger) {
	githubService, err := RegisterGithubService(sf, conf, serviceConf)
	if err != nil {
		panic(err)
	}

	pivotalService, err := RegisterPivotalService(sf, conf, serviceConf)
	if err != nil {
		log.Fatal("Could not initialize pivotal service: %s", err)
	}

	sf.Register("github", githubService)
	sf.Register("pivotal", services.Service(pivotalService))
}

func RegisterGithubService(sf *services.Services, conf *config.Config, serviceConf *services.ServiceConfig) (services.Service, error) {
	gc := services.GithubConfig{}
	gc.PublicURL = serviceConf.PublicURL
	gc.IntegrationUrl = serviceConf.IntegrationAddr
	gc.Log = serviceConf.Log
	gc.Secret = conf.Github.ClientSecret

	return services.NewGithub(gc)
}

func RegisterPivotalService(sf *services.Services, conf *config.Config, serviceConf *services.ServiceConfig) (services.Service, error) {
	pv := &services.PivotalConfig{
		ServerURL:      "",
		PublicURL:      serviceConf.PublicURL,
		IntegrationURL: serviceConf.IntegrationAddr,
	}

	return services.NewPivotal(pv, serviceConf.Log)
}
