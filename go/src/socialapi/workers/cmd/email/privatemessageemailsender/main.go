package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/privatemessageemail/privatemessageemailsender"
	"socialapi/workers/helper"
)

const Name = "PrivateMessageEmailSender"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	modelhelper.Initialize(r.Conf.Mongo)

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	handler, err := sender.New(
		redisConn, r.Log, r.Metrics,
	)
	if err != nil {
		r.Log.Error("Could not create chat email sender: %s", err)
	}

	r.ShutdownHandler = handler.Shutdown

	r.Listen()
	r.Wait()
}
