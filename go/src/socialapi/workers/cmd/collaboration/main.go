package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
	"socialapi/workers/collaboration"
	"socialapi/workers/collaboration/models"

	"github.com/koding/broker"
	"github.com/koding/runner"
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

	redisConn := runner.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	appConfig := config.MustRead(r.Conf.Path)

	// init mongo connection
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	handler := collaboration.New(r.Log, redisConn, appConfig, r.Kite)
	r.SetContext(handler)
	// only listen and operate on collaboration ping messages that are fired by the handler
	r.Register(models.Ping{}).On(collaboration.FireEventName).Handle((*collaboration.Controller).Ping)
	r.Listen()
	r.Wait()
}
