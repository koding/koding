// Package main runs the server for team worker
package main

import (
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/team"

	"github.com/koding/runner"
)

var (
	// Name holds the worker name
	Name = "Team"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	r.SetContext(team.NewController(r.Log, appConfig))
	r.Register(models.ChannelParticipant{}).OnCreate().Handle((*team.Controller).HandleParticipant)
	r.Register(models.ChannelParticipant{}).OnUpdate().Handle((*team.Controller).HandleParticipant)
	r.Register(models.ChannelParticipant{}).OnDelete().Handle((*team.Controller).HandleParticipant)
	r.Register(models.Channel{}).OnCreate().Handle((*team.Controller).HandleCreator)
	r.Register(models.Channel{}).OnDelete().Handle((*team.Controller).HandleChannel)
	r.Listen()
	r.Wait()
}
