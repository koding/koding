package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/populartopic/populartopic"
)

var (
	Name = "PopularTopic"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	redis := helper.MustInitRedisConn(r.Conf)
	// create message handler
	handler := populartopic.New(r.Log, redis)
	r.SetContext(handler)
	r.Register(models.ChannelMessageList{}).OnCreate().Handle((*populartopic.Controller).MessageSaved)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*populartopic.Controller).MessageDeleted)
	r.Listen()
	r.Wait()
}
