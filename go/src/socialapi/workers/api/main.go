package main

import (
	// _ "expvar"
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"net/http"
	// _ "net/http/pprof" // Imported for side-effect of handling /debug/pprof.
	"os"
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
	cert = flag.String("cert", "", "certificate pathname")
	key  = flag.String("key", "", "private key pathname")
	host = flag.String("host", "0.0.0.0", "listen address")
	port = flag.String("port", "7000", "listen port")

	hMux       tigertonic.HostServeMux
	mux, nsMux *tigertonic.TrieServeMux

	Name = "SocialAPI"
)

func init() {
	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "Usage: example [-cert=<cert>] [-key=<key>] [-config=<config>] [-host=<host>] [-port=<port>]")
		flag.PrintDefaults()
	}
	mux = tigertonic.NewTrieServeMux()
	mux = handlers.Inject(mux)
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

	if !flag.Parsed() {
		flag.Parse()
	}

	server := newServer(r.Conf)
	// shutdown server
	defer server.Close()

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
	if conf.FlagDebugMode {
		handler = tigertonic.Logged(handler, nil)
	}

	addr := *host + ":" + *port
	server := tigertonic.NewServer(addr, handler)

	go listener(server)
	return server
}

func listener(server *tigertonic.Server) {
	var err error
	if "" != *cert && "" != *key {
		err = server.ListenAndServeTLS(*cert, *key)
	} else {
		err = server.ListenAndServe()
	}
	if nil != err {
		panic(err)
	}
}
