package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/privatemessageemail/privatemessageemailfeeder"
	"socialapi/workers/helper"
)

var Name = "PrivateMessageEmailFeeder"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// mongo connection is used for getting account emails and email settings
	modelhelper.Initialize(r.Conf.Mongo)

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	handler := feeder.New(r.Log, redisConn)

	r.SetContext(handler)
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*feeder.Controller).AddMessageToQueue)
	r.Register(models.ChannelParticipant{}).On("channel_glanced").Handle((*feeder.Controller).GlanceChannel)
	r.Listen()
	r.Wait()
}
