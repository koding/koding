package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/common/handler"
	"socialapi/workers/common/mux"

	"github.com/koding/integration"
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

	appConfig := config.MustRead(r.Conf.Path)
	workerConfig := appConfig.WebhookMiddleware
	mc := mux.NewConfig(Name, workerConfig.Host, workerConfig.Port)
	m := mux.New(mc, r.Log, r.Metrics)
	path := appConfig.CustomDomain.Local

	h := integration.NewHandler(r.Log, path)

	if r.Conf.Environment == "dev" || r.Conf.Environment == "test" {
		path =
			fmt.Sprintf("http://%s:%s", appConfig.Integration.Host,
				appConfig.Integration.Port)
	}

	addHandlers(m, h)

	m.Listen()
	r.ShutdownHandler = m.Close

	r.Wait()
}

func addHandlers(m *mux.Mux, h *integration.Handler) {
	m.AddSessionlessHandler(
		handler.Request{
			Handler:  h.Push,
			Name:     "webhook-middleware-push",
			Type:     handler.PostRequest,
			Endpoint: "/push/{name}/{token}",
		},
	)
}
