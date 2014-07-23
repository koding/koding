package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	notificationmodels "socialapi/workers/notification/models"
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
	r.Register(models.ChannelMessageList{}).OnUpdate().Handle((*realtime.Controller).MessageListUpdated)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*realtime.Controller).MessageListDeleted)
	r.Register(models.ChannelParticipant{}).On("removed_from_channel").Handle((*realtime.Controller).ChannelParticipantRemoved)
	r.Register(models.ChannelParticipant{}).On("added_to_channel").Handle((*realtime.Controller).ChannelParticipantAdded)
	r.Register(models.ChannelParticipant{}).OnCreate().Handle((*realtime.Controller).ChannelParticipantAdded)
	r.Register(models.ChannelParticipant{}).OnUpdate().Handle((*realtime.Controller).ChannelParticipantUpdatedEvent)
	r.Register(notificationmodels.Notification{}).OnCreate().Handle((*realtime.Controller).NotifyUser)
	r.Register(notificationmodels.Notification{}).OnUpdate().Handle((*realtime.Controller).NotifyUser)
	r.Listen()
	r.Wait()
}
