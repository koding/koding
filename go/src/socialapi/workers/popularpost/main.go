package main

import (
	"fmt"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/popularpost/popularpost"
)

var (
	Name = "PopularPost"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// create message handler
	handler := popularpost.New(
		r.Log,
		helper.MustInitRedisConn(r.Conf),
	)

	r.SetContext(handler)
	r.ListenFor("api.interaction_created", (*popularpost.Controller).InteractionSaved)
	r.ListenFor("api.interaction_deleted", (*popularpost.Controller).InteractionDeleted)
	r.Listen()
	r.Wait()
}
