package main

import (
	// _ "expvar"

	"fmt"
	"koding/db/mongodb/modelhelper"
	// _ "net/http/pprof" // Imported for side-effect of handling /debug/pprof.

	"socialapi/config"
	"socialapi/workers/api/handlers"
	"socialapi/workers/common/mux"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	notificationapi "socialapi/workers/notification/api"
	"socialapi/workers/payment"
	paymentapi "socialapi/workers/payment/api"
	permissionapi "socialapi/workers/permission/api"
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
	handlers.AddHandlers(m)
	m.Listen()

	// shutdown server
	defer m.Close()

	paymentapi.AddHandlers(m)
	notificationapi.AddHandlers(m)
	trollmodeapi.AddHandlers(m)
	sitemapapi.AddHandlers(m)
	permissionapi.AddHandlers(m)

	// init redis
	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	// set default values for dev env
	if r.Conf.Environment == "dev" {
		go setDefaults(r.Log)
	}

	payment.Initialize(config.MustGet(), r.Kite)

	r.Listen()
	r.Wait()
}
