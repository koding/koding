package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/workers/common/manager"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	"socialapi/workers/notification/controller"
)

var (
	Name = "Notification"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	//create connection to RMQ for publishing realtime events
	rmq := helper.NewRabbitMQ(r.Conf, r.Log)

	cacheEnabled := r.Conf.Notification.CacheEnabled
	if cacheEnabled {
		// init redis
		redisConn := helper.MustInitRedisConn(r.Conf)
		defer redisConn.Close()
	}

	handler, err := notification.New(
		rmq,
		r.Log,
		cacheEnabled,
	)
	if err != nil {
		panic(err)
	}

	m := manager.New()
	m.Controller(handler)

	m.HandleFunc("api.message_reply_created", (*notification.Controller).CreateReplyNotification)
	m.HandleFunc("api.interaction_created", (*notification.Controller).CreateInteractionNotification)
	m.HandleFunc("api.channel_participant_created", (*notification.Controller).JoinChannel)
	m.HandleFunc("api.channel_participant_updated", (*notification.Controller).LeaveChannel)
	m.HandleFunc("api.channel_message_list_created", (*notification.Controller).SubscribeMessage)
	m.HandleFunc("api.channel_message_list_deleted", (*notification.Controller).UnsubscribeMessage)
	m.HandleFunc("api.channel_message_created", (*notification.Controller).MentionNotification)

	r.Listen(m)
	r.Wait()
}
