package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/topicfeed/topicfeed"
)

var (
	Name = "TopicFeed"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	r.SetContext(topicfeed.New(r.Log))
	r.Register(models.ChannelMessage{}).OnUpdate().Handle((*topicfeed.Controller).MessageUpdated)
	r.Register(models.ChannelMessage{}).OnDelete().Handle((*topicfeed.Controller).MessageDeleted)
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*topicfeed.Controller).MessageSaved)
	r.Listen()
	r.Wait()
}
