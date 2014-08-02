package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/pinnedpost/pinnedpost"
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
	r.Register(models.MessageReply{}).OnCreate().Handle((*pinnedpost.Controller).MessageReplyCreated)
	r.Listen()
	r.Wait()
}
