package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/realtime/realtime"

	"github.com/koding/runner"
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
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	r.SetContext(realtime.New(r.Bongo.Broker.MQ, r.Log))
	r.Register(models.ChannelMessage{}).OnUpdate().Handle((*realtime.Controller).MessageUpdated)
	r.Register(models.MessageReply{}).OnCreate().Handle((*realtime.Controller).MessageReplySaved)
	r.Register(models.MessageReply{}).OnDelete().Handle((*realtime.Controller).MessageReplyDeleted)
	r.Register(models.ChannelMessageList{}).OnCreate().Handle((*realtime.Controller).MessageListSaved)
	r.Register(models.ChannelMessageList{}).OnUpdate().Handle((*realtime.Controller).ChannelMessageListUpdated)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*realtime.Controller).MessageListDeleted)
	r.Register(models.ParticipantEvent{}).On(models.ChannelParticipant_Removed_From_Channel_Event).Handle((*realtime.Controller).ChannelParticipantRemoved)
	r.Register(models.ParticipantEvent{}).On(models.ChannelParticipant_Added_To_Channel_Event).Handle((*realtime.Controller).ChannelParticipantsAdded)
	r.Register(models.ChannelParticipant{}).OnUpdate().Handle((*realtime.Controller).ChannelParticipantUpdatedEvent)
	r.Register(models.Channel{}).OnDelete().Handle((*realtime.Controller).ChannelDeletedEvent)
	r.Register(models.Channel{}).OnUpdate().Handle((*realtime.Controller).ChannelUpdatedEvent)
	r.Listen()
	r.Wait()
}
