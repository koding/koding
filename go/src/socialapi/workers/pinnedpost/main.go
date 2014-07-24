package main

import (
	"fmt"
	"socialapi/workers/common/manager"
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

	// create message handler
	handler := pinnedpost.New(r.Log)

	m := manager.New()
	m.Controller(handler)

	m.HandleFunc("api.message_reply_created", (*pinnedpost.Controller).MessageReplyCreated)

	// create message handler
	r.Listen(m)
	r.Wait()
}
