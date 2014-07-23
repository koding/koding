package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/notification/notification"
)

var (
	Name = "Notification"
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

	handler, err := notification.New(rmq, r.Log)
	if err != nil {
		panic(err)
	}
	r.SetContext(handler)
	r.Register(models.MessageReply{}).OnCreate().Handle((*notification.Controller).CreateReplyNotification)
	r.Register(models.Interaction{}).OnCreate().Handle((*notification.Controller).CreateInteractionNotification)
	r.Register(models.ChannelParticipant{}).OnCreate().Handle((*notification.Controller).JoinChannel)
	r.Register(models.ChannelParticipant{}).OnUpdate().Handle((*notification.Controller).LeaveChannel)
	r.Register(models.ChannelMessageList{}).OnCreate().Handle((*notification.Controller).SubscribeMessage)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*notification.Controller).UnsubscribeMessage)
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*notification.Controller).MentionNotification)
	r.Listen()
	r.Wait()
}
