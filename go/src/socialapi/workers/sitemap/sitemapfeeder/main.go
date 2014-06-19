package main

import (
	"fmt"
	"socialapi/workers/common/manager"
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

	redisConn := helper.MustInitRedisConn(r.Conf.Redis)
	defer redisConn.Close()

	controller := feeder.New(r.Log)

	m := manager.New()
	m.Controller(controller)

	registerHandlers(m)

	r.Listen(m)
	r.Wait()
}

func registerHandlers(m *manager.Manager) {
	m.HandleFunc("api.channel_message_created", (*feeder.Controller).MessageAdded)
	m.HandleFunc("api.channel_message_updated", (*feeder.Controller).MessageUpdated)
	m.HandleFunc("api.channel_message_deleted", (*feeder.Controller).MessageDeleted)
	m.HandleFunc("api.channel_created", (*feeder.Controller).ChannelAdded)
	m.HandleFunc("api.channel_updated", (*feeder.Controller).ChannelUpdated)
	m.HandleFunc("api.channel_deleted", (*feeder.Controller).ChannelDeleted)
	m.HandleFunc("api.account_created", (*feeder.Controller).AccountAdded)
	m.HandleFunc("api.account_updated", (*feeder.Controller).AccountUpdated)
	m.HandleFunc("api.account_deleted", (*feeder.Controller).AccountDeleted)
}
