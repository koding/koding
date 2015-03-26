// Package main runs the server for topic moderation worker
package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/moderation/topic"
)

var (
	// Name holds the worker name
	Name = "TopicModeration"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	r.SetContext(topic.NewController(r.Log))
	r.Register(models.ChannelLink{}).OnCreate().Handle((*topic.Controller).Create)
	r.Register(models.ChannelLink{}).OnDelete().Handle((*topic.Controller).Delete)
	r.Register(models.ChannelLink{}).On(models.ModerationChannelBlacklist).Handle((*topic.Controller).Blacklist)
	r.Listen()
	r.Wait()
}
