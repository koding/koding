package main

import (
	"fmt"
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
	r.ListenFor("api.channel_message_created", (*followingfeed.Controller).MessageSaved)
	r.ListenFor("api.channel_message_update", (*followingfeed.Controller).MessageUpdated)
	r.ListenFor("api.channel_message_deleted", (*followingfeed.Controller).MessageDeleted)
	r.Listen()
	r.Wait()
}
