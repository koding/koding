package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/followingfeed/followingfeed"
)

var (
	Name = "FollowingFeed"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	r.SetContext(followingfeed.New(r.Log))
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*followingfeed.Controller).MessageSaved)
	r.Register(models.ChannelMessage{}).OnUpdate().Handle((*followingfeed.Controller).MessageUpdated)
	r.Register(models.ChannelMessage{}).OnDelete().Handle((*followingfeed.Controller).MessageDeleted)
	r.Listen()
	r.Wait()
}
