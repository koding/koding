// Package main runs the server for topic moderation worker
package main

import (
	"log"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/moderation/topic"

	"github.com/koding/runner"
)

var (
	// Name holds the worker name
	Name = "TopicModeration"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	appConfig := config.MustRead(r.Conf.Path)
	r.SetContext(topic.NewController(r.Log, appConfig))
	r.Register(models.ChannelLink{}).OnCreate().Handle((*topic.Controller).Create)
	r.Register(models.ChannelLink{}).OnDelete().Handle((*topic.Controller).Delete)
	r.Register(models.ChannelLink{}).On(models.ModerationChannelBlacklist).Handle((*topic.Controller).Blacklist)
	r.Listen()
	r.Wait()
}
