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
	broker, err := models.NewBroker(rmq, r.Log)
	if err != nil {
		fmt.Println(err)
		return
	}

	mc := mux.NewMuxConfig(Name, config.Host, config.Port)
	m := mux.NewMux(mc, r.Log)
	m.Metrics = r.Metrics

	h, err := handlers.NewHandler(rmq, pubnub, broker)
	if err != nil {
		panic(err)
	}

	h.AddHandlers(m)

	m.Listen()

	defer m.Close()

	r.SetContext(h)
	r.ListenFor("gatekeeper_channel_updated", (*handlers.Handler).UpdateChannel)
	r.Listen()

	r.Wait()
}
