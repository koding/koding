package main

import (
	"fmt"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/realtime/dispatcher/dispatcher"
	"socialapi/workers/realtime/models"
)

const Name = "Dispatcher"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// create a realtime service provider instance.
	pubnub := models.NewPubNub(r.Conf.GateKeeper.Pubnub, r.Log)
	defer pubnub.Close()

	// later on broker support must be removed
	rmq := helper.NewRabbitMQ(r.Conf, r.Log)
	broker, err := models.NewBroker(rmq, r.Log)
	if err != nil {
		fmt.Println(err)
		return
	}

	c, err := dispatcher.NewController(rmq, pubnub, broker)
	if err != nil {
		panic(err)
	}

	r.SetContext(c)
	r.ListenFor("dispatcher_channel_updated", (*dispatcher.Controller).UpdateChannel)
	r.ListenFor("dispatcher_message_updated", (*dispatcher.Controller).UpdateMessage)
	r.ListenFor("dispatcher_notify_user", (*dispatcher.Controller).NotifyUser)
	r.ListenFor("api.channel_message_created", (*dispatcher.Controller).GrantMessagePublicAccess)
	r.Listen()

	r.Wait()
}
