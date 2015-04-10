package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/workers/common/mux"
	"socialapi/workers/integration/webhook"

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

	mc := mux.NewConfig(Name)
	m := mux.New(mc, r.Log)
	m.Metrics = r.Metrics

	h := webhook.NewHandler(r.Log)
	h.AddHandlers(m)

	go r.Listen()

	m.Listen()
	defer m.Close()

	r.Wait()
}
