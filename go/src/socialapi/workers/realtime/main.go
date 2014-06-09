package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/manager"
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

	handler, err := realtime.New(rmq, r.Log)
	if err != nil {
		panic(err)
	}

	m := manager.New()
	m.Controller(handler)

	// m.HandleFunc("api.channel_message_created", (*realtime.Controller).MessageSaved)
	m.HandleFunc("api.channel_message_updated", (*realtime.Controller).MessageUpdated)
	// m.HandleFunc("api.channel_message_deleted", (*realtime.Controller).MessageDeleted)
	m.HandleFunc("api.interaction_created", (*realtime.Controller).InteractionSaved)
	m.HandleFunc("api.interaction_deleted", (*realtime.Controller).InteractionDeleted)
	m.HandleFunc("api.message_reply_created", (*realtime.Controller).MessageReplySaved)
	m.HandleFunc("api.message_reply_deleted", (*realtime.Controller).MessageReplyDeleted)
	m.HandleFunc("api.channel_message_list_created", (*realtime.Controller).MessageListSaved)
	m.HandleFunc("api.channel_message_list_updated", (*realtime.Controller).MessageListUpdated)
	m.HandleFunc("api.channel_message_list_deleted", (*realtime.Controller).MessageListDeleted)
	m.HandleFunc("api.channel_participant_removed_from_channel", (*realtime.Controller).ChannelParticipantRemovedFromChannelEvent)
	m.HandleFunc("api.channel_participant_added_to_channel", (*realtime.Controller).ChannelParticipantAddedToChannelEvent)
	m.HandleFunc("api.channel_participant_created", (*realtime.Controller).ChannelParticipantAddedToChannelEvent)
	m.HandleFunc("api.channel_participant_updated", (*realtime.Controller).ChannelParticipantUpdatedEvent)
	m.HandleFunc("notification.notification_created", (*realtime.Controller).NotifyUser)
	m.HandleFunc("notification.notification_updated", (*realtime.Controller).NotifyUser)

	// create message handler
	r.Listen(m)
	r.Wait()
}
