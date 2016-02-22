package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	sender "socialapi/workers/email/privatemessageemail/privatemessageemailsender"

	"github.com/koding/runner"
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

	handler, err := sender.New(
		redisConn, r.Log, r.Metrics, appConfig,
	)
	if err != nil {
		r.Log.Error("Could not create chat email sender: %s", err)
	}

	r.ShutdownHandler = handler.Shutdown

	r.Listen()
	r.Wait()
}
