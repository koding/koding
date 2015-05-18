package main

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	algoliaapi "socialapi/workers/algoliaconnector/api"
	"socialapi/workers/api/handlers"
	collaboration "socialapi/workers/collaboration/api"
	"socialapi/workers/common/mux"
	mailapi "socialapi/workers/email/mailparse/api"
	"socialapi/workers/helper"
	topicmoderationapi "socialapi/workers/moderation/topic/api"
	notificationapi "socialapi/workers/notification/api"
	"socialapi/workers/payment"
	paymentapi "socialapi/workers/payment/api"
	permissionapi "socialapi/workers/permission/api"
	sitemapapi "socialapi/workers/sitemap/api"
	trollmodeapi "socialapi/workers/trollmode/api"

	"github.com/koding/runner"
)

var (
	Name = "SocialAPI"
)

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	// appConfig
	c := config.MustRead(r.Conf.Path)

	mc := mux.NewConfig(Name, r.Conf.Host, r.Conf.Port)
	mc.Debug = r.Conf.Debug
	m := mux.New(mc, r.Log, r.Metrics)

	handlers.AddHandlers(m)
	permissionapi.AddHandlers(m)
	topicmoderationapi.AddHandlers(m)
	collaboration.AddHandlers(m)
	paymentapi.AddHandlers(m)
	notificationapi.AddHandlers(m)
	trollmodeapi.AddHandlers(m)
	sitemapapi.AddHandlers(m)
	mailapi.AddHandlers(m)
	algoliaapi.AddHandlers(m, r.Log)

	// init redis
	redisConn := runner.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

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
	r.ShutdownHandler = m.Close

	r.Listen()
	r.Wait()
}
