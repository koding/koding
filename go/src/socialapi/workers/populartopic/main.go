package main

import (
	"fmt"
	"socialapi/workers/helper"
	"socialapi/workers/populartopic/populartopic"
)

var (
	Name = "PopularTopic"
)

func main() {
	runner := &helper.Runner{}
	if err := runner.Init(Name); err != nil {
		fmt.Println(err)
		return
	}

	redis := helper.MustInitRedisConn(runner.Conf.Redis)
	// create message handler
	handler := populartopic.NewPopularTopicsController(runner.Log, redis)

	runner.Listen(handler)
	runner.Close()
}
