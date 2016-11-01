package main

import (
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
	"socialapi/workers/presence"

	"github.com/koding/runner"
)

var (
	name = "Presence"
)

func main() {
	r := runner.New(name)
	if err := r.Init(); err != nil {
		log.Fatal(err.Error())
	}

	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	r.SetContext(presence.New(r.Log, appConfig))
	r.Register(presence.Ping{}).On(presence.EventName).Handle((*presence.Controller).Ping)
	r.Listen()
	r.Wait()
}
