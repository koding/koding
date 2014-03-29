package main

import (
	_ "expvar"
	"flag"
	"fmt"
	"koding/tools/config"

	"github.com/koding/logging"

	_ "net/http/pprof" // Imported for side-effect of handling /debug/pprof.
	"os"
	"os/signal"
	"socialapi/workers/api/handlers"
	"socialapi/workers/helper"
	"syscall"

	"github.com/koding/bongo"
	"github.com/rcrowley/go-tigertonic"
)

var (
	Bongo       *bongo.Bongo
	log         logging.Logger
	cert        = flag.String("cert", "", "certificate pathname")
	key         = flag.String("key", "", "private key pathname")
	flagConfig  = flag.String("config", "", "pathname of JSON configuration file")
	listen      = flag.String("listen", "127.0.0.1:8000", "listen address")
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
	conf        *config.Config

	hMux       tigertonic.HostServeMux
	mux, nsMux *tigertonic.TrieServeMux
)

type context struct {
	Username string
}

func init() {
	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "Usage: example [-cert=<cert>] [-key=<key>] [-config=<config>] [-listen=<listen>]")
		flag.PrintDefaults()
	}
	mux = tigertonic.NewTrieServeMux()
	mux = handlers.Inject(mux)

}

func main() {
	flag.Parse()
	if *flagProfile == "" {
		log.Fatal("Please define config file with -c")
	}
	conf = config.MustConfig(*flagProfile)
	log = helper.CreateLogger("SocialAPI", *flagDebug)

	server := newServer()
	// Example use of server.Close and server.Wait to stop gracefully.
	go listener(server)

	// panics if not successful
	Bongo = helper.MustInitBongo(conf)

	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGQUIT, syscall.SIGTERM)

	log.Info("Recieved %v", <-ch)
	shutdown()
}

}

func newServer() *tigertonic.Server {
	// go metrics.Log(
	// 	metrics.DefaultRegistry,
	// 	60e9,
	// 	stdlog.New(os.Stderr, "metrics ", stdlog.Lmicroseconds),
	// )

	server := tigertonic.NewServer(
		*listen,
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
