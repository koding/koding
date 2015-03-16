package main

import (
	// _ "expvar"

	"fmt"
	"koding/db/mongodb/modelhelper"
	// _ "net/http/pprof" // Imported for side-effect of handling /debug/pprof.

	"socialapi/config"
	"socialapi/workers/api/handlers"
	collaboration "socialapi/workers/collaboration/api"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/runner"
	mailapi "socialapi/workers/email/mailparse/api"
	notificationapi "socialapi/workers/notification/api"
	"socialapi/workers/payment"
	paymentapi "socialapi/workers/payment/api"
	sitemapapi "socialapi/workers/sitemap/api"
	trollmodeapi "socialapi/workers/trollmode/api"
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

	config.MustRead(r.Conf.Path)

	mc := mux.NewConfig(Name, r.Conf.Host, r.Conf.Port)
	mc.Debug = r.Conf.Debug
	m := mux.New(mc, r.Log)

	m.Metrics = r.Metrics
	handlers.AddHandlers(m)
	m.Listen()
	// shutdown server
	defer m.Close()

	collaboration.AddHandlers(m)
	paymentapi.AddHandlers(m)
	notificationapi.AddHandlers(m)
	trollmodeapi.AddHandlers(m)
	sitemapapi.AddHandlers(m)
	mailapi.AddHandlers(m)

	// init redis
	redisConn := runner.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	// init mongo connection
	appConfig := config.MustRead(r.Conf.Path)
	modelhelper.Initialize(appConfig.Mongo)
	defer modelhelper.Close()

	// set default values for dev env
	if r.Conf.Environment == "dev" {
		go setDefaults(r.Log)
	}

	payment.Initialize(config.MustGet())

	r.Listen()
	r.Wait()
}
