package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/email/dailyemail/dailyemail"
	"socialapi/workers/email/emailmodels"

	"github.com/koding/runner"
)

var Name = "DailyEmail"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	// init redis connection
	redisConn := runner.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	es := emailmodels.NewEmailSettings(appConfig)

	handler, err := dailyemail.New(r.Log, es)
	if err != nil {
		r.Log.Error("an error occurred", err)
		return
	}

	r.ShutdownHandler = handler.Shutdown

	r.Listen()
	r.Wait()
}
