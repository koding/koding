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
	rmqConn, err := rmq.Connect("NewNotificationWorkerController")
	if err != nil {
		panic(err)
	}
	defer rmqConn.Conn().Close()

	handler := notification.New(rmq, r.Log)

	r.SetContext(handler)
	r.Register(models.MessageReply{}).OnCreate().Handle((*notification.Controller).CreateReplyNotification)
	r.Register(models.Interaction{}).OnCreate().Handle((*notification.Controller).CreateInteractionNotification)
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*notification.Controller).HandleMessage)
	r.Register(models.ChannelMessage{}).OnDelete().Handle((*notification.Controller).DeleteNotification)
	r.Listen()
	r.Wait()
}
