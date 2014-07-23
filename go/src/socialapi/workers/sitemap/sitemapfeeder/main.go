package main

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/sitemapfeeder/feeder"
)

var (
	Name = "SitemapFeeder"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	r.SetContext(feeder.New(r.Log))
	registerHandlers(r)
	r.Listen(m)
	r.Wait()
}

func registerHandlers(r *runner.Runner) {
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*feeder.Controller).MessageAdded)
	r.Register(models.ChannelMessage{}).OnUpdate().Handle((*feeder.Controller).MessageUpdated)
	r.Register(models.ChannelMessage{}).OnDelete().Handle((*feeder.Controller).MessageDeleted)
	r.Register(models.ChannelMessageList{}).OnCreate().Handle((*feeder.Controller).ChannelMessageListAdded)
	r.Register(models.ChannelMessageList{}).OnUpdate().Handle((*feeder.Controller).ChannelMessageListUpdated)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*feeder.Controller).ChannelMessageListDeleted)
	r.Register(models.Account{}).OnCreate().Handle((*feeder.Controller).AccountAdded)
	r.Register(models.Account{}).OnUpdate().Handle((*feeder.Controller).AccountUpdated)
	r.Register(models.Account{}).OnDelete().Handle((*feeder.Controller).AccountDeleted)
}
