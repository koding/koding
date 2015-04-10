// Package main runs the server for team worker
package main

import (
	"fmt"
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
		fmt.Println(err)
		return
	}

	appConfig := config.MustRead(r.Conf.Path)
	r.SetContext(team.NewController(r.Log, appConfig))
	r.Register(models.ChannelParticipant{}).OnCreate().Handle((*team.Controller).HandleParticipant)
	r.Register(models.ChannelParticipant{}).OnUpdate().Handle((*team.Controller).HandleParticipant)
	r.Register(models.ChannelParticipant{}).OnDelete().Handle((*team.Controller).HandleParticipant)
	r.Listen()
	r.Wait()
}
