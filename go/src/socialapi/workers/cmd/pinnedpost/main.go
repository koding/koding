package main

import (
	"fmt"
	"socialapi/workers/common/runner"
	"socialapi/workers/pinnedpost"
)

var (
	Name = "PinnedPost"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	r.SetContext(pinnedpost.New(r.Log))
	// block listening to events of message create, because we are not using the pinned message feature anymore
	// r.Register(models.MessageReply{}).OnCreate().Handle((*pinnedpost.Controller).MessageReplyCreated)
	r.Listen()
	r.Wait()
}
