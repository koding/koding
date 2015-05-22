package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/workers/email/dailyemail"

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

	redisConn := r.Bongo.MustGetRedisConn()

	handler, err := dailyemail.New(redisConn, r.Log, appConfig)
	if err != nil {
		r.Log.Error("an error occurred", err)
		return
	}

	r.ShutdownHandler = handler.Shutdown

	r.Listen()
	r.Wait()
}
