package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/notification"

	"github.com/koding/runner"
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
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	r.SetContext(notification.New(r.Bongo.Broker.MQ, r.Log))
	r.Register(models.MessageReply{}).OnCreate().Handle((*notification.Controller).CreateReplyNotification)
	r.Register(models.Interaction{}).OnCreate().Handle((*notification.Controller).CreateInteractionNotification)
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*notification.Controller).HandleMessage)
	r.Register(models.ChannelMessage{}).OnDelete().Handle((*notification.Controller).DeleteNotification)
	r.Listen()
	r.Wait()
}
