package main

import (
	"fmt"
	"log"
	"socialapi/workers/collaboration"
	"socialapi/workers/collaboration/models"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"

	"github.com/koding/broker"
)

var (
	Name = "Collaboration"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// remove QOS, we want to consume all the messages from RMQ
	if err := r.Bongo.Broker.Sub.(*broker.Consumer).Consumer.QOS(0); err != nil {
		log.Fatalf("couldnt remove the QOS %# v", err)
	}

	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	handler := collaboration.New(r.Log, redisConn, r.Conf)
	r.SetContext(handler)
	// only listen and operate on collaboration ping messages that are fired by the handler
	r.Register(models.Ping{}).On(collaboration.FireEventName).Handle((*collaboration.Controller).Ping)
	r.Listen()
	r.Wait()
}
