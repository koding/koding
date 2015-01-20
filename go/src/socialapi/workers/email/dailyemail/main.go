package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/runner"
	"socialapi/workers/email/dailyemail/dailyemail"
	"socialapi/workers/email/emailmodels"
	"socialapi/workers/helper"
)

var Name = "DailyEmail"

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

	es := emailmodels.NewEmailSettings(r.Conf)

	handler, err := dailyemail.New(r.Log, es)
	if err != nil {
		r.Log.Error("an error occurred", err)
		return
	}

	r.ShutdownHandler = handler.Shutdown

	r.Listen()
	r.Wait()
}
