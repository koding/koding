package main

import (
	"fmt"
	"socialapi/workers/followingfeed/followingfeed"
	"socialapi/workers/helper"
)

var (
	Name = "FollowingFeed"
)

func main() {
	runner := &helper.Runner{}
	if err := runner.Init(Name); err != nil {
		fmt.Println(err)
		return
	}

	// create message handler
	handler := followingfeed.NewFollowingFeedController(runner.Log)

	runner.Listen(handler)
	runner.Close()
}
