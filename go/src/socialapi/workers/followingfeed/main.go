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

	// create message handler
	handler := followingfeed.New(r.Log)

	r.Listen(handler)
	r.Close()
}
