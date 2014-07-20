package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/realtime/realtime"
)

var (
	Name = "Realtime"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(r.Conf, r.Log)

	c, err := realtime.New(rmq, r.Log)
	if err != nil {
		panic(err)
	}

	r.SetContext(c)
	// r.ListenFor.HandleFunc("api.channel_message_created", (*realtime.Controller).MessageSaved)
	r.ListenFor("api.channel_message_updated", (*realtime.Controller).MessageUpdated)
	// r.ListenFor.HandleFunc("api.channel_message_deleted", (*realtime.Controller).MessageDeleted)
	r.ListenFor("api.interaction_created", (*realtime.Controller).InteractionSaved)
	r.ListenFor("api.interaction_deleted", (*realtime.Controller).InteractionDeleted)
	r.ListenFor("api.message_reply_created", (*realtime.Controller).MessageReplySaved)
	r.ListenFor("api.message_reply_deleted", (*realtime.Controller).MessageReplyDeleted)
	r.ListenFor("api.channel_message_list_created", (*realtime.Controller).MessageListSaved)
	r.ListenFor("api.channel_message_list_updated", (*realtime.Controller).MessageListUpdated)
	r.ListenFor("api.channel_message_list_deleted", (*realtime.Controller).MessageListDeleted)
	r.ListenFor("api.channel_participant_removed_from_channel", (*realtime.Controller).ChannelParticipantRemoved)
	r.ListenFor("api.channel_participant_added_to_channel", (*realtime.Controller).ChannelParticipantAdded)
	r.ListenFor("api.channel_participant_created", (*realtime.Controller).ChannelParticipantAdded)
	r.ListenFor("api.channel_participant_updated", (*realtime.Controller).ChannelParticipantUpdatedEvent)
	r.ListenFor("notification.notification_created", (*realtime.Controller).NotifyUser)
	r.ListenFor("notification.notification_updated", (*realtime.Controller).NotifyUser)
	r.Listen()
	r.Wait()
}
