package main

import (
	"log"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/topicfeed"

	"github.com/koding/runner"
)

var (
	Name = "TopicFeed"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	appConfig := config.MustRead(r.Conf.Path)
	r.SetContext(topicfeed.New(r.Log, appConfig))
	r.Register(models.ChannelMessage{}).OnUpdate().Handle((*topicfeed.Controller).MessageUpdated)
	r.Register(models.ChannelMessage{}).OnDelete().Handle((*topicfeed.Controller).MessageDeleted)
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*topicfeed.Controller).MessageSaved)
	r.Listen()
	r.Wait()
}
