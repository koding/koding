package mux

import (
	"fmt"
	"koding/artifact"
	"net/http"
	"socialapi/models"
	"socialapi/workers/common/handler"
	"sync"

	"github.com/koding/logging"
	"github.com/koding/metrics"
	tigertonic "github.com/rcrowley/go-tigertonic"
)

type Config struct {
	Name  string
	Host  string
	Port  string
	Debug bool
}

func NewConfig(name, host string, port string) *Config {
	return &Config{
		Name: name,
		Host: host,
		Port: port,
	}
}

type Mux struct {
	Metrics *metrics.Metrics

	mux    *tigertonic.TrieServeMux
	nsMux  *tigertonic.TrieServeMux
	server *tigertonic.Server
	config *Config
	log    logging.Logger

	closing bool
	closeMu sync.Mutex
}

func New(mc *Config, log logging.Logger, metrics *metrics.Metrics) *Mux {
	m := &Mux{
		mux:     tigertonic.NewTrieServeMux(),
		nsMux:   tigertonic.NewTrieServeMux(),
		Metrics: metrics,
	}

	// add namespace support into
	// all handlers
	m.nsMux.HandleNamespace("", m.mux)
	m.nsMux.HandleNamespace("/1.0", m.mux)
	tigertonic.SnakeCaseHTTPEquivErrors = true

	m.log = log
	m.config = mc

	m.addDefaultHandlers()

	return m
}

func (m *Mux) AddHandler(request handler.Request) {
	if request.Metrics == nil {
		request.Metrics = m.Metrics
	}
	hHandler := handler.Wrapper(request)
	hHandler = handler.BuildHandlerWithContext(hHandler, m.log)

	m.mux.Handle(request.Type, request.Endpoint, hHandler)
}

func (m *Mux) AddSessionlessHandler(request handler.Request) {
	if request.Metrics == nil {
		request.Metrics = m.Metrics
	}
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
		Handler:  artifact.HealthCheckHandler(m.config.Name),
	})

	m.AddUnscopedHandler(handler.Request{
		Type:     handler.GetRequest,
		Endpoint: "/",
		Handler: func(w http.ResponseWriter, r *http.Request) {
			fmt.Fprintf(w, "Hello from %s", m.config.Name)
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

	handler := http.Handler(tigertonic.WithContext(m.nsMux, models.Context{}))
	if m.config.Debug {
		h := tigertonic.Logged(handler, nil)
		h.Logger = NewTigerTonicLogger(m.log)
		handler = h
	}

	addr := fmt.Sprintf("%s:%s", m.config.Host, m.config.Port)

	m.server = tigertonic.NewServer(addr, handler)
	go m.listener()
}

func (m *Mux) Handler(r *http.Request) (http.Handler, string) {
	return m.mux.Handler(r)
}

func (m *Mux) Close() {
	m.closeMu.Lock()
	defer m.closeMu.Unlock()

	m.closing = true

	if m.server != nil {
		m.server.Close()
	}
}

func (m *Mux) listener() {
	if err := m.server.ListenAndServe(); err != nil {
		m.closeMu.Lock()
		defer m.closeMu.Unlock()

		if !m.closing {
			panic(err)
		}
	}
}
