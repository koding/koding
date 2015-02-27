package main

import (
	"fmt"
	"socialapi/workers/common/runner"
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

	r.SetContext(dispatcher.NewController(r.Bongo.Broker.MQ, pubnub))
	r.ListenFor("dispatcher_channel_updated", (*dispatcher.Controller).UpdateChannel)
	r.ListenFor("dispatcher_message_updated", (*dispatcher.Controller).UpdateMessage)
	r.ListenFor("dispatcher_notify_user", (*dispatcher.Controller).NotifyUser)
	r.ListenFor("event.channel_participant_removed_from_channel", (*dispatcher.Controller).RevokeChannelAccess)
	r.Listen()

	r.Wait()
}
