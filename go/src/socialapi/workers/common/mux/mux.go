package mux

import (
	"fmt"
	"koding/artifact"
	"net/http"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/common/handler"

	"github.com/koding/logging"
	"github.com/koding/metrics"
	"github.com/rcrowley/go-tigertonic"
)

type Mux struct {
	Metrics *metrics.Metrics

	mux    *tigertonic.TrieServeMux
	nsMux  *tigertonic.TrieServeMux
	server *tigertonic.Server
	name   string
	conf   *config.Config
	log    logging.Logger
}

func NewMux(name string, conf *config.Config, log logging.Logger) *Mux {
	m := &Mux{
		mux:   tigertonic.NewTrieServeMux(),
		nsMux: tigertonic.NewTrieServeMux(),
		name:  name,
	}

	// add namespace support into
	// all handlers
	m.nsMux.HandleNamespace("", m.mux)
	m.nsMux.HandleNamespace("/1.0", m.mux)
	tigertonic.SnakeCaseHTTPEquivErrors = true

	m.conf = conf
	m.log = log

	m.addDefaultHandlers()

	return m
}

func (m *Mux) AddHandler(request handler.Request) {
	request.Metrics = m.Metrics
	hHandler := handler.Wrapper(request)
	hHandler = handler.BuildHandlerWithContext(hHandler)

	m.mux.Handle(request.Type, request.Endpoint, hHandler)
}

func (m *Mux) AddSessionlessHandler(request handler.Request) {
	request.Metrics = m.Metrics
	hHandler := handler.Wrapper(request)

	m.mux.Handle(request.Type, request.Endpoint, hHandler)
}

func (m *Mux) AddUnscopedHandler(request handler.Request) {
	m.mux.HandleFunc(request.Type, request.Endpoint, request.Handler.(func(http.ResponseWriter, *http.Request)))
}

func (m *Mux) addDefaultHandlers() *tigertonic.TrieServeMux {
	m.AddUnscopedHandler(handler.Request{
		Type:     handler.GetRequest,
		Endpoint: "/version",
		Handler:  artifact.VersionHandler(),
	})

	m.AddUnscopedHandler(handler.Request{
		Type:     handler.GetRequest,
		Endpoint: "/healthCheck",
		Handler:  artifact.HealthCheckHandler(m.name),
	})

	m.AddUnscopedHandler(handler.Request{
		Type:     handler.GetRequest,
		Endpoint: "/",
		Handler: func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintf(w, "Hello from %s", m.name)
		},
	})

	return m.mux
}

func (m *Mux) Listen() {
	// go metrics.Log(
	// 	metrics.DefaultRegistry,
	// 	60e9,
	// 	stdlog.New(os.Stderr, "metrics ", stdlog.Lmicroseconds),
	// )

	var handler http.Handler
	handler = tigertonic.WithContext(m.nsMux, models.Context{})
	if m.conf.Debug {
		h := tigertonic.Logged(handler, nil)
		h.Logger = NewTigerTonicLogger(m.log)
		handler = h
	}

	addr := m.conf.Host + ":" + m.conf.Port

	m.server = tigertonic.NewServer(addr, handler)
	go m.listener()
}

func (m *Mux) Close() {
	m.server.Close()
}

func (m *Mux) listener() {
	if err := m.server.ListenAndServe(); err != nil {
		panic(err)
	}
}
