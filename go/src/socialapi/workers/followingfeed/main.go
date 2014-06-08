package main

import (
	"fmt"
	"socialapi/workers/common/manager"
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

	m := manager.New()
	m.Controller(followingfeed.New(r.Log))

	m.HandleFunc("api.channel_message_created", (*followingfeed.Controller).MessageSaved)
	m.HandleFunc("api.channel_message_update", (*followingfeed.Controller).MessageUpdated)
	m.HandleFunc("api.channel_message_deleted", (*followingfeed.Controller).MessageDeleted)

	r.Listen(m)
	r.Wait()
}
