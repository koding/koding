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
	"socialapi/workers/payment"
	paymentapi "socialapi/workers/payment/api"
)

var (
	Name = "SocialAPI"
)

func init() {

	// mux = notificationapi.InitHandlers(mux)
	// mux = trollmodeapi.InitHandlers(mux)
	// mux = sitemapapi.InitHandlers(mux)
}

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	m := mux.NewMux(Name, r.Conf, r.Log)
	m.Metrics = r.Metrics
	handlers.AddHandlers(m)
	m.Listen()

	// shutdown server
	defer m.Close()

	// init payment handlers, this done here instead of in `init()`
	// like others so we can've access to `metrics`
	paymentapi.AddHandlers(m)
	// init redis
	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	// set default values for dev env
	if r.Conf.Environment == "dev" {
		go setDefaults(r.Log)
	}

	payment.Initialize(config.MustGet())

	r.Listen()
	r.Wait()
}
