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
	sitemapapi "socialapi/workers/sitemap/api"
	trollmodeapi "socialapi/workers/trollmode/api"

	"github.com/rcrowley/go-tigertonic"
)

var (
	hMux       tigertonic.HostServeMux
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

	server := newServer(r.Conf)
	// shutdown server
	defer server.Close()

	mux = handlers.Inject(mux, r.Metrics)

	// init redis
	redisConn := helper.MustInitRedisConn(r.Conf)
	defer redisConn.Close()

	// init mongo connection
	modelhelper.Initialize(r.Conf.Mongo)

	r.Wait()
}

func newServer(conf *config.Config) *tigertonic.Server {
	// go metrics.Log(
	// 	metrics.DefaultRegistry,
	// 	60e9,
	// 	stdlog.New(os.Stderr, "metrics ", stdlog.Lmicroseconds),
	// )

	var handler http.Handler
	handler = tigertonic.WithContext(nsMux, models.Context{})
	if conf.Debug {
		handler = tigertonic.Logged(handler, nil)
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
