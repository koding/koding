package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/integration/eventsender"

	"github.com/koding/runner"
)

var Name = "EventSender"

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)

	handler := eventsender.New(appConfig, r.Log)

	r.SetContext(handler)
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*eventsender.Controller).MessageCreated)
	r.Register(models.Channel{}).OnCreate().Handle((*eventsender.Controller).ChannelCreated)
	r.ListenFor("social.workspace_created", (*eventsender.Controller).WorkspaceCreated)
	r.Listen()
	r.Wait()
}
