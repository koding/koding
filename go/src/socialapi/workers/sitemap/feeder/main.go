package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/manager"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/feeder/feeder"
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

	modelhelper.Initialize(r.Conf.Mongo)

	rmq := helper.NewRabbitMQ(r.Conf, r.Log)
	redisConn := helper.MustInitRedisConn(r.Conf.Redis)
	defer redisConn.Close()

	handler, err := sitemapfeeder.New(rmq, r.Log)
	if err != nil {
		panic(err)
	}

	m := manager.New()
	m.Controller(handler)

	registerHandlers(m)

	r.Listen(m)
	r.Wait()
}

func registerHandlers(m *manager.Manager) {
	m.HandleFunc("api.channel_message_created", (*sitemapfeeder.Controller).MessageAdded)
	m.HandleFunc("api.channel_message_updated", (*sitemapfeeder.Controller).MessageUpdated)
	m.HandleFunc("api.channel_message_deleted", (*sitemapfeeder.Controller).MessageDeleted)
	m.HandleFunc("api.channel_created", (*sitemapfeeder.Controller).ChannelAdded)
	m.HandleFunc("api.channel_updated", (*sitemapfeeder.Controller).ChannelUpdated)
	m.HandleFunc("api.channel_deleted", (*sitemapfeeder.Controller).ChannelDeleted)
	m.HandleFunc("api.account_created", (*sitemapfeeder.Controller).AccountAdded)
	m.HandleFunc("api.account_updated", (*sitemapfeeder.Controller).AccountUpdated)
	m.HandleFunc("api.account_deleted", (*sitemapfeeder.Controller).AccountDeleted)
}
