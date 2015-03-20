package main

import (
	"fmt"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/runner"
	api "socialapi/workers/realtime/gatekeeper"
	"socialapi/workers/realtime/models"
)

const Name = "Gatekeeper"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	config := r.Conf.GateKeeper
	// create a realtime service provider instance.
	pubnub := models.NewPubNub(r.Conf.GateKeeper.Pubnub, r.Log)
	defer pubnub.Close()

	mc := mux.NewConfig(Name, config.Host, config.Port)
	m := mux.New(mc, r.Log)
	m.Metrics = r.Metrics

	h := api.NewHandler(pubnub, r.Log)

	h.AddHandlers(m)

	// consume messages from RMQ
	go r.Listen()

	m.Listen()
	defer m.Close()

	r.Wait()
}
