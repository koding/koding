package main

import (
	"fmt"
	"socialapi/workers/common/manager"
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

	m := manager.New()
	m.Controller(handler)
	m.HandleFunc("api.interaction_created", (*popularpost.Controller).InteractionSaved)
	m.HandleFunc("api.interaction_deleted", (*popularpost.Controller).InteractionDeleted)

	// create message handler
	r.Listen(m)
	r.Wait()
}
