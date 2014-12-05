package main

import (
	"fmt"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/runner"
	"socialapi/workers/gatekeeper/handlers"
	"socialapi/workers/gatekeeper/models"
	"socialapi/workers/helper"
)

const Name = "GateKeeper"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	config := r.Conf.GateKeeper
	// create a realtime service provider instance.
	pubnub := models.NewPubnub(r.Conf.GateKeeper.Pubnub, r.Log)
	defer pubnub.Close()

	// later on broker support must be removed
	rmq := helper.NewRabbitMQ(r.Conf, r.Log)
	broker, err := models.NewBroker(rmq)
	if err != nil {
		fmt.Println(err)
		return
	}

	mc := mux.NewMuxConfig(Name, config.Host, config.Port)
	m := mux.NewMux(mc, r.Log)
	m.Metrics = r.Metrics

	h := handlers.NewHandler(pubnub, broker)

	h.AddHandlers(m)

	m.Listen()

	defer m.Close()

	r.Wait()
}
