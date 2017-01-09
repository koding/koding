package main

import (
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
	"socialapi/workers/collaboration"
	"socialapi/workers/collaboration/models"

	"github.com/koding/broker"
	"github.com/koding/cache"
	"github.com/koding/runner"
)

var (
	// Name specifies runner name for collaboration
	Name = "Collaboration"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	if r.Kite == nil {
		r.Log.Fatal("couldnt init kite")
	}

	// remove QOS, we want to consume all the messages from RMQ
	if err := r.Bongo.Broker.Sub.(*broker.Consumer).Consumer.QOS(0); err != nil {
		r.Log.Fatal("couldnt remove the QOS %# v", err)
	}

	appConfig := config.MustRead(r.Conf.Path)

	// init mongo connection
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// init with defaults & ensure expireAt index
	mongoCache := cache.NewMongoCacheWithTTL(modelhelper.Mongo.Session, cache.StartGC(), cache.MustEnsureIndexExpireAt())
	defer mongoCache.StopGC()

	handler := collaboration.New(r.Log, mongoCache, appConfig, r.Kite)
	r.SetContext(handler)
	// only listen and operate on collaboration ping messages that are fired by the handler
	r.Register(models.Ping{}).On(collaboration.FireEventName).Handle((*collaboration.Controller).Ping)
	r.Listen()
	r.Wait()
}
