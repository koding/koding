package main

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	feeder "socialapi/workers/sitemap/sitemapfeeder"

	"github.com/koding/runner"
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

	appConfig := config.MustRead(r.Conf.Path)

	conf := *r.Conf
	conf.Redis.DB = appConfig.Sitemap.RedisDB
	redisConn := runner.MustInitRedisConn(&conf)
	defer redisConn.Close()

	r.SetContext(feeder.New(r.Log, redisConn))
	registerHandlers(r)
	r.Listen()
	r.Wait()
}

func registerHandlers(r *runner.Runner) {
	r.Register(models.ChannelMessage{}).OnCreate().Handle((*feeder.Controller).MessageAdded)
	r.Register(models.ChannelMessage{}).OnUpdate().Handle((*feeder.Controller).MessageUpdated)
	r.Register(models.ChannelMessage{}).OnDelete().Handle((*feeder.Controller).MessageDeleted)
	r.Register(models.ChannelMessageList{}).OnCreate().Handle((*feeder.Controller).ChannelMessageListAdded)
	r.Register(models.ChannelMessageList{}).OnUpdate().Handle((*feeder.Controller).ChannelMessageListUpdated)
	r.Register(models.ChannelMessageList{}).OnDelete().Handle((*feeder.Controller).ChannelMessageListDeleted)
}
