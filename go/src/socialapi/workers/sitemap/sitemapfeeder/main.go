package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
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

	modelhelper.Initialize(r.Conf.Mongo)

	rmq := helper.NewRabbitMQ(r.Conf, r.Log)
	redisConn := helper.MustInitRedisConn(r.Conf.Redis)
	defer redisConn.Close()

	handler, err := feeder.New(rmq, r.Log)
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
