package main

import (
	"fmt"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/realtime/dispatcher"
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

	// When we use the same RMQ connection for both, we received
	// 'Exception (504) Reason: "CHANNEL_ERROR - unexpected method in connection state running"'
	// error at some point. It needs debugging.
	rmqBroker, err := helper.NewRabbitMQ(r.Conf, r.Log).Connect()
	if err != nil {
		fmt.Println(err)
		return
	}
	defer rmqBroker.Conn().Close()

	broker := models.NewBroker(rmqBroker, r.Log)

	r.SetContext(dispatcher.NewController(r.Bongo.Broker.MQ, pubnub, broker))
	r.ListenFor("dispatcher_channel_updated", (*dispatcher.Controller).UpdateChannel)
	r.ListenFor("dispatcher_message_updated", (*dispatcher.Controller).UpdateMessage)
	r.ListenFor("dispatcher_notify_user", (*dispatcher.Controller).NotifyUser)
	r.ListenFor("event.channel_participant_removed_from_channel", (*dispatcher.Controller).RevokeChannelAccess)
	r.Listen()

	r.Wait()
}
