package main

import (
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/notification/notification"
)

var (
	Name        = "Notification"
	flagHidePMs = flag.Bool("h", false, "Hide all pms")
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	if *flagHidePMs {
		notification.HidePMNotifications()
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
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*notification.Controller).HandleMessage)
	r.Register(models.ChannelMessage{}).OnDelete().Handle((*notification.Controller).DeleteNotification)
	r.Listen()
	r.Wait()
}
