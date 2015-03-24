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
	"socialapi/workers/helper"
	notificationapi "socialapi/workers/notification/api"
	"socialapi/workers/payment"
	paymentapi "socialapi/workers/payment/api"
	sitemapapi "socialapi/workers/sitemap/api"
	trollmodeapi "socialapi/workers/trollmode/api"
	"strconv"
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

	port, _ := strconv.Atoi(r.Conf.Port)

	mc := mux.NewConfig(Name, r.Conf.Host, port)
	mc.Debug = r.Conf.Debug
	m := mux.New(mc, r.Log)

	m.Metrics = r.Metrics
	handlers.AddHandlers(m, r.Metrics)
	m.Listen()
	// shutdown server
	defer m.Close()

	collaboration.AddHandlers(m, r.Metrics)
	paymentapi.AddHandlers(m, r.Metrics)
	notificationapi.AddHandlers(m, r.Metrics)
	trollmodeapi.AddHandlers(m, r.Metrics)
	sitemapapi.AddHandlers(m, r.Metrics)
	mailapi.AddHandlers(m, r.Metrics)

	// init redis
	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)
	defer modelhelper.Close()

	mmdb, err := helper.ReadGeoIPDB(r.Conf)
	if err != nil {
		r.Log.Critical("ip persisting wont work err: %s", err.Error())
	} else {
		defer mmdb.Close()
	}

	// set default values for dev env
	if r.Conf.Environment == "dev" {
		go setDefaults(r.Log)
	}

	payment.Initialize(config.MustGet())

	r.Listen()
	r.Wait()
}
