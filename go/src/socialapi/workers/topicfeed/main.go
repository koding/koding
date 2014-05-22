package main

import (
	"fmt"
	"socialapi/workers/helper"
	"socialapi/workers/topicfeed/topicfeed"
)

var (
	Name = "TopicFeed"
)

func main() {
	runner := &helper.Runner{}
	if err := runner.Init(Name); err != nil {
		fmt.Println(err)
		return
	}

	// create message handler
	handler := topicfeed.NewTopicFeedController(runner.Log)

	runner.Listen(handler)
	runner.Close()
}
