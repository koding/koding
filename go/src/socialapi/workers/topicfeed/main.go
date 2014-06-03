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

	// create message handler
	handler := topicfeed.New(r.Log)

	r.Listen(handler)
	r.Wait()
}
