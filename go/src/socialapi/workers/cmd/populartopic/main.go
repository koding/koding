package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/populartopic"

	"github.com/koding/runner"
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

	config.MustRead(r.Conf.Path)

	redis := runner.MustInitRedisConn(r.Conf)
	// create message handler
	handler := populartopic.New(r.Log, redis)
	r.SetContext(handler)
	r.Register(models.ChannelMessageList{}).OnCreate().Handle((*populartopic.Controller).MessageSaved)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*populartopic.Controller).MessageDeleted)
	r.Listen()
	r.Wait()
}
