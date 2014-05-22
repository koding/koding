package main

import (
	"fmt"
	"socialapi/workers/helper"
	"socialapi/workers/popularpost/popularpost"
)

var (
	Name = "PopularPost"
)

func main() {
	runner := &helper.Runner{}
	if err := runner.Init(Name); err != nil {
		fmt.Println(err)
		return
	}

	// create message handler
	handler := popularpost.NewPopularPostController(
		runner.Log,
		helper.MustInitRedisConn(runner.Conf.Redis),
	)

	runner.Listen(handler)
	runner.Close()
}
