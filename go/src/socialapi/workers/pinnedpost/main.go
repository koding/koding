package main

import (
	"fmt"
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
	r.ListenFor("api.channel_message_created", (*pinnedpost.Controller).MessageCreated)
	r.ListenFor("api.message_reply_created", (*pinnedpost.Controller).MessageReplyCreated)
	r.Listen()
	r.Wait()
}
