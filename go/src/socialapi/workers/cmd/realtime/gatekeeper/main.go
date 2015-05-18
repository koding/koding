package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/common/mux"
	api "socialapi/workers/realtime/gatekeeper"
	"socialapi/workers/realtime/models"

	"github.com/koding/runner"
)

const Name = "Gatekeeper"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// create a realtime service provider instance.
	pubnub := models.NewPubNub(appConfig.GateKeeper.Pubnub, r.Log)
	defer pubnub.Close()

	mc := mux.NewConfig(Name, appConfig.GateKeeper.Host, appConfig.GateKeeper.Port)
	m := mux.New(mc, r.Log, r.Metrics)

	h := api.NewHandler(pubnub, r.Log)

	h.AddHandlers(m)

	// consume messages from RMQ
	go r.Listen()

	m.Listen()
	r.ShutdownHandler = m.Close

	r.Wait()
}
