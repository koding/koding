package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/dailyemailnotifier/controller"
	"socialapi/workers/emailnotifier/models"
	"socialapi/workers/helper"
)

var Name = "DailyEmailNotifier"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	// init redis connection
	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	es := &models.EmailSettings{
		Username:           r.Conf.SendGrid.Username,
		Password:           r.Conf.SendGrid.Password,
		DefaultFromMail:    r.Conf.SendGrid.DefaultFromMail,
		DefaultFromAddress: r.Conf.SendGrid.DefaultFromAddress,
		ForcedRecipient:    r.Conf.SendGrid.ForcedRecipient,
	}

	handler, err := controller.New(r.Log, es)
	if err != nil {
		r.Log.Error("an error occurred", err)
		return
	}

	r.ShutdownHandler = handler.Shutdown
	r.Wait()
}
