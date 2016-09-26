package main

import (
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
	"socialapi/workers/email/dailyemail"

	"github.com/koding/runner"
)

var Name = "DailyEmail"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	redisConn := r.Bongo.MustGetRedisConn()

	handler, err := dailyemail.New(redisConn, r.Log, appConfig)
	if err != nil {
		r.Log.Fatal("an error occurred: %s", err)
	}

	r.ShutdownHandler = handler.Shutdown

	r.Listen()
	r.Wait()
}
