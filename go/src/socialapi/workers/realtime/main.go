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
	rmqConn, err := rmq.Connect("NewRealtimeWorkerController")
	if err != nil {
		panic(err)
	}
	defer rmqConn.Conn().Close()

	c := realtime.New(rmq, r.Log)

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
	r.Register(models.ParticipantEvent{}).On(models.ChannelParticipant_Removed_From_Channel_Event).Handle((*realtime.Controller).ChannelParticipantRemoved)
	r.Register(models.ParticipantEvent{}).On(models.ChannelParticipant_Added_To_Channel_Event).Handle((*realtime.Controller).ChannelParticipantsAdded)
	r.Register(models.ChannelParticipant{}).OnUpdate().Handle((*realtime.Controller).ChannelParticipantUpdatedEvent)
	r.Register(models.Channel{}).OnDelete().Handle((*realtime.Controller).ChannelDeletedEvent)
	r.Register(notificationmodels.Notification{}).OnCreate().Handle((*realtime.Controller).NotifyUser)
	r.Register(notificationmodels.Notification{}).OnUpdate().Handle((*realtime.Controller).NotifyUser)
	r.Listen()
	r.Wait()
}
