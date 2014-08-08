package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
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
	r.Register(models.ChannelMessage{}).OnUpdate().Handle((*realtime.Controller).MessageUpdated)
	r.Register(models.Interaction{}).OnCreate().Handle((*realtime.Controller).InteractionSaved)
	r.Register(models.Interaction{}).OnDelete().Handle((*realtime.Controller).InteractionDeleted)
	r.Register(models.MessageReply{}).OnCreate().Handle((*realtime.Controller).MessageReplySaved)
	r.Register(models.MessageReply{}).OnDelete().Handle((*realtime.Controller).MessageReplyDeleted)
	r.Register(models.ChannelMessageList{}).OnCreate().Handle((*realtime.Controller).MessageListSaved)
	r.Register(models.ChannelMessageList{}).On("pinned_channel_list_updated").Handle((*realtime.Controller).PinnedChannelListUpdated)
	r.Register(models.ChannelMessageList{}).OnUpdate().Handle((*realtime.Controller).ChannelMessageListUpdated)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*realtime.Controller).MessageListDeleted)
	r.Register(models.ChannelParticipant{}).On("removed_from_channel").Handle((*realtime.Controller).ChannelParticipantRemoved)
	r.Register(models.ChannelParticipant{}).On("added_to_channel").Handle((*realtime.Controller).ChannelParticipantAdded)
	r.Register(models.ChannelParticipant{}).OnCreate().Handle((*realtime.Controller).ChannelParticipantAdded)
	r.Register(models.ChannelParticipant{}).OnUpdate().Handle((*realtime.Controller).ChannelParticipantUpdatedEvent)
	r.Listen()
	r.Wait()
}
