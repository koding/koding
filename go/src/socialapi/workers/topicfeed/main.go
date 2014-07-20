package main

import (
	"fmt"
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
	r.ListenFor("api.channel_message_updated", (*topicfeed.Controller).MessageUpdated)
	r.ListenFor("api.channel_message_updated", (*topicfeed.Controller).MessageUpdated)
	r.ListenFor("api.channel_message_deleted", (*topicfeed.Controller).MessageDeleted)
	r.ListenFor("api.channel_message_created", (*topicfeed.Controller).MessageSaved)
	r.Listen()
	r.Wait()
}
