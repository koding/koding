package main

import (
	"fmt"
	"socialapi/workers/common/manager"
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

	m := manager.New()
	m.Controller(topicfeed.New(r.Log))

	m.HandleFunc("api.channel_message_update", (*topicfeed.Controller).MessageUpdated)
	m.HandleFunc("api.channel_message_deleted", (*topicfeed.Controller).MessageDeleted)
	m.HandleFunc("api.channel_message_created", (*topicfeed.Controller).MessageSaved)

	// create message handler
	r.Listen(m)
	r.Wait()
}
