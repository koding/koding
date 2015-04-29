package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/common/mux"
	"socialapi/workers/realtime/gatekeeper"

	"github.com/koding/runner"
)

var (
	Name = "IntegrationWebhook"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	iConfig := appConfig.Integration

	mc := mux.NewConfig(Name, iConfig.Host, iConfig.Port)
	m := mux.New(mc, r.Log)
	m.Metrics = r.Metrics

	h, err := api.NewHandler(r.Log)
	if err != nil {
		r.Log.Fatal("Could not initialize webhook worker: %s", err)
	}

	if r.Conf.Environment == "dev" || r.Conf.Environment == "test" {
		h.RevProxyUrl =
			fmt.Sprintf("http://%s:%s", appConfig.Integration.Host,
				appConfig.Integration.Port)
	}

	h.AddHandlers(m)

	go r.Listen()

	m.Listen()
	defer m.Close()

	r.Wait()
}
