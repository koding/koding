package main

import (
	// _ "expvar"

	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	// _ "net/http/pprof" // Imported for side-effect of handling /debug/pprof.

	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/api/handlers"
	"socialapi/workers/common/runner"
	"socialapi/workers/helper"
	notificationapi "socialapi/workers/notification/api"
	paymentapi "socialapi/workers/payment/api"
	"socialapi/workers/payment/stripe"
	sitemapapi "socialapi/workers/sitemap/api"
	trollmodeapi "socialapi/workers/trollmode/api"

	"github.com/rcrowley/go-tigertonic"
)

var (
	mux, nsMux *tigertonic.TrieServeMux

	Name = "SocialAPI"
)

func init() {
	mux = tigertonic.NewTrieServeMux()
	mux = notificationapi.InitHandlers(mux)
	mux = trollmodeapi.InitHandlers(mux)
	mux = sitemapapi.InitHandlers(mux)

	// add namespace support into
	// all handlers
	nsMux = tigertonic.NewTrieServeMux()
	nsMux.HandleNamespace("", mux)
	nsMux.HandleNamespace("/1.0", mux)
	tigertonic.SnakeCaseHTTPEquivErrors = true

}

func main() {
	r := runner.New(Name)
	if err := r.Init(); err != nil {
		fmt.Println(err)
		return
	}

	server := newServer(r)
	// shutdown server
	defer server.Close()

	mux = handlers.Inject(mux, r.Metrics)

	// init payment handlers, this done here instead of in `init()`
	// like others so we can've access to `metrics`
	mux = paymentapi.InitHandlers(mux, r.Metrics)

	mux.HandleFunc("GET", "/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello from socialapi")
	})

	// init redis
	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	// init stripe client
	stripe.InitializeClientKey(config.MustGet().Stripe.SecretToken)

	go func() {
		err := stripe.CreateDefaultPlans()
		if err != nil {
			fmt.Println(err)
			panic(err)
		}
	}()

	r.Wait()
}

func newServer(r *runner.Runner) *tigertonic.Server {
	// go metrics.Log(
	// 	metrics.DefaultRegistry,
	// 	60e9,
	// 	stdlog.New(os.Stderr, "metrics ", stdlog.Lmicroseconds),
	// )

	conf := r.Conf

	var handler http.Handler
	handler = tigertonic.WithContext(nsMux, models.Context{})
	if conf.Debug {
		h := tigertonic.Logged(handler, nil)
		h.Logger = NewTigerTonicLogger(r.Log)
		handler = h
	}

	addr := conf.Host + ":" + conf.Port
	server := tigertonic.NewServer(addr, handler)

	go listener(server)
	return server
}

func listener(server *tigertonic.Server) {
	if err := server.ListenAndServe(); nil != err {
		panic(err)
	}
}
