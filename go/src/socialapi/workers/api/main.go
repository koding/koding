package main

import (
	// _ "expvar"
	"flag"
	"fmt"
	"koding/db/mongodb/modelhelper"

	// _ "net/http/pprof" // Imported for side-effect of handling /debug/pprof.
	"os"
	"os/signal"
	"socialapi/workers/api/handlers"
	"socialapi/workers/helper"
	notificationapi "socialapi/workers/notification/api"
	"syscall"
	"github.com/coreos/go-log/log"
	"github.com/rcrowley/go-tigertonic"
)

var (
	cert       = flag.String("cert", "", "certificate pathname")
	key        = flag.String("key", "", "private key pathname")
	flagConfig = flag.String("config", "", "pathname of JSON configuration file")
	host       = flag.String("host", "0.0.0.0", "listen address")
	port       = flag.String("port", "7000", "listen port")

	hMux       tigertonic.HostServeMux
	mux, nsMux *tigertonic.TrieServeMux

	Name = "SocialAPI"
)

type context struct {
	Username string
}

func init() {
	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "Usage: example [-cert=<cert>] [-key=<key>] [-config=<config>] [-host=<host>] [-port=<port>]")
		flag.PrintDefaults()
	}
	mux = tigertonic.NewTrieServeMux()
	mux = handlers.Inject(mux)
	mux = notificationapi.InitHandlers(mux)
}

func main() {
	runner := &helper.Runner{}
	if err := runner.Init(Name); err != nil {
		fmt.Println(err)
		return
	}

	if !flag.Parsed() {
		flag.Parse()
	}

	server := newServer()
	// shutdown server
	defer server.Close()

	// init redis
	redisConn := helper.MustInitRedisConn(runner.Conf.Redis)
	defer redisConn.Close()

	// init mongo connection
	modelhelper.Initialize(runner.Conf.Mongo)

	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGQUIT, syscall.SIGTERM)

	log.Info("Received %v", <-ch)
}

func newServer() *tigertonic.Server {
	// go metrics.Log(
	// 	metrics.DefaultRegistry,
	// 	60e9,
	// 	stdlog.New(os.Stderr, "metrics ", stdlog.Lmicroseconds),
	// )

	addr := *host + ":" + *port
	server := tigertonic.NewServer(
		addr,
		tigertonic.Logged(
			tigertonic.WithContext(mux, context{}),
			nil,
		),
	)
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
