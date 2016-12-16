package main

import (
	"koding/db/mongodb/modelhelper"
	"log"
	"socialapi/config"
	algoliaapi "socialapi/workers/algoliaconnector/api"
	"socialapi/workers/api/handlers"
	"socialapi/workers/api/modules/account"
	"socialapi/workers/api/modules/channel"
	"socialapi/workers/api/modules/client"
	"socialapi/workers/api/modules/message"
	"socialapi/workers/api/modules/messagelist"
	"socialapi/workers/api/modules/participant"
	"socialapi/workers/api/modules/privatechannel"
	"socialapi/workers/api/modules/reply"
	collaboration "socialapi/workers/collaboration/api"
	"socialapi/workers/common/mux"
	credential "socialapi/workers/credentials/api"
	emailapi "socialapi/workers/email/api"
	mailapi "socialapi/workers/email/mailparse/api"
	"socialapi/workers/helper"
	"socialapi/workers/payment"
	paymentapi "socialapi/workers/payment/api"
	presenceapi "socialapi/workers/presence/api"
	realtimeapi "socialapi/workers/realtime/api"
	slackapi "socialapi/workers/slack/api"

	"github.com/koding/runner"
)

var (
	Name = "SocialAPI"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		log.Fatal(err)
	}

	// appConfig
	c := config.MustRead(r.Conf.Path)

	mc := mux.NewConfig(Name, r.Conf.Host, r.Conf.Port)
	mc.Debug = r.Conf.Debug
	m := mux.New(mc, r.Log, r.Metrics)

	// init redis
	redisConn := r.Bongo.MustGetRedisConn()

	m.SetRedis(redisConn)

	handlers.AddHandlers(m)
	collaboration.AddHandlers(m)
	paymentapi.AddHandlers(m)
	mailapi.AddHandlers(m)
	algoliaapi.AddHandlers(m, r.Log)

	account.AddHandlers(m)
	channel.AddHandlers(m)
	client.AddHandlers(m)
	message.AddHandlers(m)
	messagelist.AddHandlers(m)
	participant.AddHandlers(m)
	privatechannel.AddHandlers(m)
	reply.AddHandlers(m)
	realtimeapi.AddHandlers(m)
	presenceapi.AddHandlers(m)
	slackapi.AddHandlers(m, c)
	credential.AddHandlers(m, r.Log, c)
	emailapi.AddHandlers(m)

	// init mongo connection
	modelhelper.Initialize(c.Mongo)
	defer modelhelper.Close()

	mmdb, err := helper.ReadGeoIPDB(c)
	if err != nil {
		r.Log.Critical("ip persisting wont work err: %s", err.Error())
	} else {
		defer mmdb.Close()
	}

	// set default values for dev env
	if r.Conf.Environment == "dev" {
		go setDefaults(r.Log)
	}

	payment.Initialize(c)

	m.Listen()
	// shutdown server
	defer m.Close()

	r.Listen()
	r.Wait()
}
