package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/emailmodels"
	"socialapi/workers/email/privatemessageemail/privatemessageemailsender/sender"
)

const Name = "PrivateMessageEmailSender"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	redisConn := runner.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	es := emailmodels.NewEmailSettings(appConfig)

	handler, err := sender.New(
		redisConn, r.Log, es, r.Metrics,
	)
	if err != nil {
		r.Log.Error("Could not create chat email sender: %s", err)
	}

	r.ShutdownHandler = handler.Shutdown

	r.Listen()
	r.Wait()
}
