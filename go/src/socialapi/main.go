package main

import (
	_ "expvar" // Imported for side-effect of handling /debug/vars.
	"flag"
	"fmt"
	"log"
	_ "net/http/pprof"
	// Imported for side-effect of handling /debug/pprof.
	"os"
	"os/signal"
	"socialapi/handlers"
	"strings"
	"syscall"
	"github.com/rcrowley/go-tigertonic"
)

var (
	cert   = flag.String("cert", "", "certificate pathname")
	key    = flag.String("key", "", "private key pathname")
	config = flag.String("config", "", "pathname of JSON configuration file")
	listen = flag.String("listen", "127.0.0.1:8000", "listen address")

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
	log.SetFlags(log.Ltime | log.Lmicroseconds | log.Lshortfile)

	mux = tigertonic.NewTrieServeMux()
	mux = handlers.Inject(mux)

}

func main() {
	flag.Parse()

	// Example of parsing a configuration file.
	c := &Config{}
	if err := tigertonic.Configure(*config, c); nil != err {
		log.Fatalln(err)
	}

	server := newServer()
	// Example use of server.Close and server.Wait to stop gracefully.
	go listener(server)

	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGQUIT, syscall.SIGTERM)

	log.Println(<-ch)
	server.Close()
}

func newServer() *tigertonic.Server {
	return tigertonic.NewServer(
		*listen,
		tigertonic.CountedByStatus(
			tigertonic.Logged(
				tigertonic.WithContext(mux, context{}),
				func(s string) string {
					return strings.Replace(s, "SECRET", "REDACTED", -1)
				},
			),
			"http",
			nil,
		),
	)
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
