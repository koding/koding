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
		helper.MustInitRedisConn(r.Conf.Redis),
	)

	r.Listen(handler)
	r.Close()
}
