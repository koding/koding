package main

import (
	"errors"
	_ "expvar" // Imported for side-effect of handling /debug/vars.
	"flag"
	"fmt"
	"log"
	"net/http"
	_ "net/http/pprof" // Imported for side-effect of handling /debug/pprof.
	"net/url"
	"os"
	"os/signal"
	"strings"
	"syscall"

	"github.com/rcrowley/go-metrics"
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

// A version string that can be set with
//
//     -ldflags "-X main.Version VERSION"
//
// at compile-time.
var Version string

type context struct {
	Username string
}

func init() {
	flag.Usage = func() {
		fmt.Fprintln(os.Stderr, "Usage: example [-cert=<cert>] [-key=<key>] [-config=<config>] [-listen=<listen>]")
		flag.PrintDefaults()
	}
	log.SetFlags(log.Ltime | log.Lmicroseconds | log.Lshortfile)

	// We'll use this CORSBuilder to set Access-Control-Allow-Origin headers
	// on certain endpoints.
	cors := tigertonic.NewCORSBuilder().AddAllowedOrigins("*")

	// Register endpoints defined in top-level functions below with example
	// uses of Timed go-metrics wrapper.
	mux = tigertonic.NewTrieServeMux()
	mux.Handle(
		"POST",
		"/stuff",
		tigertonic.Timed(tigertonic.Marshaled(create), "POST-stuff", nil),
	)
	mux.Handle(
		"GET",
		"/stuff/{id}",
		cors.Build(tigertonic.Timed(
			tigertonic.Marshaled(get),
			"GET-stuff-id",
			nil,
		)),
	)
	mux.Handle(
		"POST",
		"/stuff/{id}",
		tigertonic.Timed(tigertonic.Marshaled(update), "POST-stuff-id", nil),
	)

	// Example use of the If middleware to forbid access to certain endpoints
	// under certain conditions (certain conditions being all conditions in
	// this example).
	mux.Handle("GET", "/forbidden", cors.Build(tigertonic.If(
		func(*http.Request) (http.Header, error) {
			return nil, tigertonic.Forbidden{errors.New("forbidden")}
		},
		tigertonic.Marshaled(func(*url.URL, http.Header, interface{}) (int, http.Header, interface{}, error) {
			return http.StatusOK, nil, &MyResponse{}, nil
		}),
	)))

	// Example use of the HTTPBasicAuth middleware to require a username and
	// password for access to certain endpoints.
	mux.Handle("GET", "/authorized", tigertonic.HTTPBasicAuth(
		map[string]string{"username": "password"},
		"Tiger Tonic",
		tigertonic.Marshaled(func(*url.URL, http.Header, interface{}) (int, http.Header, interface{}, error) {
			return http.StatusOK, nil, &MyResponse{}, nil
		}),
	))

	// Example use of the First middleware and Context to share per-request
	// state across handlers.  The context type is set in WithContext below.
	mux.Handle("GET", "/context", tigertonic.If(
		func(r *http.Request) (http.Header, error) {
			tigertonic.Context(r).(*context).Username = "rcrowley"
			return nil, nil
		},
		tigertonic.Marshaled(func(u *url.URL, h http.Header, _ interface{}, c *context) (int, http.Header, interface{}, error) {
			return http.StatusOK, nil, &MyResponse{ID: c.Username}, nil
		}),
	))

	// Example use of a metrics.Registry's JSON output.
	mux.Handle(
		"GET",
		"/metrics.json",
		tigertonic.Marshaled(func(*url.URL, http.Header, interface{}) (int, http.Header, metrics.Registry, error) {
			return http.StatusOK, nil, metrics.DefaultRegistry, nil
		}),
	)

	// Example use of the version endpoint.
	mux.Handle("GET", "/version", tigertonic.Version(Version))

	// Example use of namespaces.
	nsMux = tigertonic.NewTrieServeMux()
	nsMux.HandleNamespace("", mux)
	nsMux.HandleNamespace("/1.0", mux)

	// Example use of virtual hosts.
	hMux = tigertonic.NewHostServeMux()
	hMux.Handle("example.com", nsMux)

	// Register http.DefaultServeMux on a subdomain for access to
	// standard library features such as /debug/pprof and /debug/vars
	// as imported at the top of this file.
	hMux.Handle("go.example.com", http.DefaultServeMux)

}

func main() {
	flag.Parse()

	// Example use of go-metrics.
	go metrics.Log(
		metrics.DefaultRegistry,
		60e9,
		log.New(os.Stderr, "metrics ", log.Lmicroseconds),
	)

	// Example of parsing a configuration file.
	c := &Config{}
	if err := tigertonic.Configure(*config, c); nil != err {
		log.Fatalln(err)
	}

	server := tigertonic.NewServer(
		*listen,

		// Example use of go-metrics to track HTTP status codes.
		tigertonic.CountedByStatus(

			// Example use of request logging, redacting the word SECRET
			// wherever it appears.
			tigertonic.Logged(

				// Example use of WithContext, which is required in order to
				// use Context within any handlers.  The second argument is a
				// zero value of the type to be used for all actual request
				// contexts.
				tigertonic.WithContext(hMux, context{}),

				func(s string) string {
					return strings.Replace(s, "SECRET", "REDACTED", -1)
				},
			),
			"http",
			nil,
		),
	)

	// Example use of server.Close to stop gracefully.
	go func() {
		var err error
		if "" != *cert && "" != *key {
			err = server.ListenAndServeTLS(*cert, *key)
		} else {
			err = server.ListenAndServe()
		}
		if nil != err {
			log.Println(err)
		}
	}()
	ch := make(chan os.Signal)
	signal.Notify(ch, syscall.SIGINT, syscall.SIGQUIT, syscall.SIGTERM)
	log.Println(<-ch)
	server.Close()

}

// POST /stuff
func create(u *url.URL, h http.Header, rq *MyRequest) (int, http.Header, *MyResponse, error) {
	return http.StatusCreated, http.Header{
		"Content-Location": {fmt.Sprintf(
			"%s://%s/1.0/stuff/%s", // TODO Don't hard-code this.
			u.Scheme,
			u.Host,
			rq.ID,
		)},
	}, &MyResponse{rq.ID, rq.Stuff}, nil
}

// GET /stuff/{id}
func get(u *url.URL, h http.Header, _ interface{}) (int, http.Header, *MyResponse, error) {
	return http.StatusOK, nil, &MyResponse{u.Query().Get("id"), "STUFF"}, nil
}

// POST /stuff/{id}
func update(u *url.URL, h http.Header, rq *MyRequest) (int, http.Header, *MyResponse, error) {
	return http.StatusAccepted, nil, &MyResponse{u.Query().Get("id"), "STUFF"}, nil
}
