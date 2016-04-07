package kit

import (
	"fmt"
	"go/format"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/schema"
)

// GenerateKitWorker generates the worker system for base kit
func GenerateKitWorker(context *common.Context, s *schema.Schema) ([]common.Output, error) {
	var outputs []common.Output

	for name, template := range templates {
		path := fmt.Sprintf(
			"%s/kitworker/%s.go",
			context.Config.Target,
			name,
		)

		api, err := format.Source([]byte(template))
		if err != nil {
			return nil, err
		}

		outputs = append(outputs, common.Output{
			Content: api,
			Path:    path,
		})
	}

	return outputs, nil

}

var templates = map[string]string{
	"instrumenting": `package kitworker

import (
    "encoding/json"
    "fmt"
    "time"

    "github.com/go-kit/kit/endpoint"
    "github.com/go-kit/kit/log"
    "github.com/go-kit/kit/metrics"
    "golang.org/x/net/context"
)

// DefaultMiddlewares provides bare bones for default middlewares with
// requestLatency, requestCount and requestLogging
func DefaultMiddlewares(method string, requestCount metrics.Counter, requestLatency metrics.Histogram, logger log.Logger) endpoint.Middleware {
    return endpoint.Chain(
        RequestLatencyMiddleware(method, requestLatency),
        RequestCountMiddleware(method, requestCount),
        RequestLoggingMiddleware(method, logger),
    )
}

// RequestCountMiddleware prepares a request counter endpoint.Middleware for
// package wide usage
func RequestCountMiddleware(method string, requestCount metrics.Counter) endpoint.Middleware {
    return func(next endpoint.Endpoint) endpoint.Endpoint {
        return func(ctx context.Context, request interface{}) (response interface{}, err error) {
            defer func() {
                methodField := metrics.Field{Key: "method", Value: method}
                errorField := metrics.Field{Key: "error", Value: fmt.Sprintf("%v", err)}
                requestCount.With(methodField).With(errorField).Add(1)
            }()

            response, err = next(ctx, request)
            return
        }
    }
}

// RequestLatencyMiddleware prepares a request latency calculator
// endpoint.Middleware for package wide usage
func RequestLatencyMiddleware(method string, requestLatency metrics.Histogram) endpoint.Middleware {
    return func(next endpoint.Endpoint) endpoint.Endpoint {
        return func(ctx context.Context, request interface{}) (response interface{}, err error) {
            defer func(begin time.Time) {
                methodField := metrics.Field{Key: "method", Value: method}
                errorField := metrics.Field{Key: "error", Value: fmt.Sprintf("%v", err)}
                requestLatency.With(methodField).With(errorField).Observe(int64(time.Since(begin)))
            }(time.Now())

            response, err = next(ctx, request)
            return
        }
    }
}

// RequestLoggingMiddleware prepares a request logger endpoint.Middleware for
// package wide usage
func RequestLoggingMiddleware(method string, logger log.Logger) endpoint.Middleware {
    return func(next endpoint.Endpoint) endpoint.Endpoint {
        return func(ctx context.Context, request interface{}) (response interface{}, err error) {
            defer func(begin time.Time) {
                input, _ := json.Marshal(request)
                output, _ := json.Marshal(response)
                _ = logger.Log(
                    "method", method,
                    "input", string(input),
                    "output", string(output),
                    "err", err,
                    "took", time.Since(begin),
                )
            }(time.Now())
            response, err = next(ctx, request)
            return
        }
    }
}
`,

	"client": `package kitworker

import (
    "net/url"
    "strings"

    "github.com/go-kit/kit/circuitbreaker"
    "github.com/go-kit/kit/endpoint"
    "github.com/go-kit/kit/loadbalancer"
    kitratelimit "github.com/go-kit/kit/ratelimit"
    "github.com/go-kit/kit/tracing/zipkin"
    httptransport "github.com/go-kit/kit/transport/http"
    jujuratelimit "github.com/juju/ratelimit"
    "github.com/sony/gobreaker"
)

// LoadBalancerF
type LoadBalancerF func(factory loadbalancer.Factory) loadbalancer.LoadBalancer

// ClientOption holds the required parameters for configuring a client
type ClientOption struct {
    // Host holds the host's name
    Host string

    // ZipkinCollector holds the collector for zipkin tracing
    ZipkinCollector zipkin.Collector

    // DisableCircuitBreaker disables circuit breaking functionality
    DisableCircuitBreaker bool

    // CircuitBreaker holds the custom circuit breaker, if not set a default one
    // will be created with default settings
    CircuitBreaker *gobreaker.CircuitBreaker

    // DisableRateLimiter disables rate limiting functionality
    DisableRateLimiter bool

    // QPS holds the configration parameter for rate limiting outgoing requests
    // to remote client. Must be set othervise all requests will be blocked
    // unless rate limiting is disabled
    QPS int

    // RateLimiter holds the custom rate limiter, if not set a default one will be created automatically
    RateLimiter *jujuratelimit.Bucket

    // TransportOpts holds custom httptransport.ClientOption array will be
    // appended to the end of the autogenerated ClientOptions
    TransportOpts []httptransport.ClientOption

    // Middlewares holds custom endpoint.Middleware array will be appended to
    // the end of the autogenerated Middlewares
    Middlewares []endpoint.Middleware

    // LoadBalancerCreator creates the loadbalancing strategy after getting the factory
    LoadBalancerCreator LoadBalancerF
}

// Configure prepares middlewares and clientOptions from the client options
//
// If required:
//   Adds circuitbreaker from "github.com/sony/gobreaker"
//   Adds ratelimiting from  "github.com/juju/ratelimit"
//   Adds request tracing from "github.com/go-kit/kit/tracing/zipkin"
func (c ClientOption) Configure(moduleName, funcName string) ([]endpoint.Middleware, []httptransport.ClientOption) {
    var transportOpts []httptransport.ClientOption
    var middlewares []endpoint.Middleware

    // if circuit braker is not disabled, add it as a middleware
    if !c.DisableCircuitBreaker {
        cb := c.CircuitBreaker

        if c.CircuitBreaker == nil {
            // create a default circuit breaker
            cb = gobreaker.NewCircuitBreaker(gobreaker.Settings{})
        }

        middlewares = append(middlewares, circuitbreaker.Gobreaker(cb))
    }

    // if rate limiter is not disabled, add it as a middleware
    if !c.DisableRateLimiter {
        rateLimiter := c.RateLimiter

        if c.RateLimiter == nil {
            // create a default rate limiter
            rateLimiter = jujuratelimit.NewBucketWithRate(float64(c.QPS), int64(c.QPS))
        }

        middlewares = append(middlewares, kitratelimit.NewTokenBucketLimiter(rateLimiter))
    }

    // enable tracing if required
    if c.Host != "" && c.ZipkinCollector != nil {
        endpointSpan := zipkin.MakeNewSpanFunc(c.Host, moduleName, funcName)
        // set tracing parameters to outgoing requests
        endpointTrace := zipkin.ToRequest(endpointSpan)
        // add tracing
        transportOpts = append(transportOpts, httptransport.SetClientBefore(endpointTrace))

        // add annotation as middleware to server
        middlewares = append(middlewares, zipkin.AnnotateClient(endpointSpan, c.ZipkinCollector))
    }

    // If any custom middlewares are passed include them
    if len(c.Middlewares) > 0 {
        middlewares = append(middlewares, c.Middlewares...)
    }

    // If any client options are passed include them in client creation
    if len(c.TransportOpts) > 0 {
        transportOpts = append(transportOpts, c.TransportOpts...)
    }

    return middlewares, transportOpts
}

// CreateProxyURL creates an URL as proxy URL
func CreateProxyURL(instance, endpoint string) *url.URL {
    if !strings.HasPrefix(instance, "http") {
        instance = "http://" + instance
    }
    u, err := url.Parse(instance)
    if err != nil {
        panic(err)
    }
    if u.Path == "" {
        u.Path = endpoint
    }

    return u
}
`,

	"server": `package kitworker

import (
    "github.com/go-kit/kit/endpoint"
    "github.com/go-kit/kit/log"
    "github.com/go-kit/kit/metrics"
    "github.com/go-kit/kit/tracing/zipkin"
    httptransport "github.com/go-kit/kit/transport/http"
)

// ServerOption holds the required parameters for configuring a server
type ServerOption struct {
    // Host holds the host's name
    Host string

    // ZipkinCollector holds the collector for zipkin tracing
    ZipkinCollector zipkin.Collector

    // LogErrors configures whether server should log error responses or not
    LogErrors bool

    // LogRequests configures if the server should log incoming requests or not
    LogRequests bool

    // Latency holds the metric metric for request latency metric collection, if
    // not set Latency metrics will not be collected
    Latency metrics.Histogram

    // Counter holds the metrics.Counter metric for request count metric
    // collection, if not set RequestCountMetrics will not be collected
    Counter metrics.Counter

    // ServerOptions holds custom httptransport.ServerOption array, will be
    // appended to the end of the autogenerated
    ServerOptions []httptransport.ServerOption

    // Middlewares holds custom endpoint.Middleware array will be appended to
    // the end of the autogenerated Middlewares
    Middlewares []endpoint.Middleware
}

// Configure prepares middlewares and serverOptions from the client options
//
// If required:
//   Adds RequestLatencyMiddleware
//   Adds RequestCountMiddleware
//   Adds RequestLoggingMiddleware
//   Adds Zipkin Tracing
//   Adds httptransport.ServerErrorLogger
func (s ServerOption) Configure(moduleName, funcName string, logger log.Logger) ([]endpoint.Middleware, []httptransport.ServerOption) {

    var serverOpts []httptransport.ServerOption
    var middlewares []endpoint.Middleware

    if s.Latency != nil {
        middlewares = append(middlewares, RequestLatencyMiddleware(funcName, s.Latency))
    }

    if s.Counter != nil {
        middlewares = append(middlewares, RequestCountMiddleware(funcName, s.Counter))
    }

    if s.LogRequests {
        middlewares = append(middlewares, RequestLoggingMiddleware(funcName, logger))
    }

    // enable tracing if required
    if s.Host != "" && s.ZipkinCollector != nil {
        tracingLogger := log.NewContext(logger).With("component", "tracing")

        endpointSpan := zipkin.MakeNewSpanFunc(s.Host, moduleName, funcName)
        endpointTrace := zipkin.ToContext(endpointSpan, tracingLogger)
        // add tracing
        serverOpts = append(serverOpts, httptransport.ServerBefore(endpointTrace))
        // add annotation as middleware to server
        middlewares = append(middlewares, zipkin.AnnotateServer(endpointSpan, s.ZipkinCollector))
    }

    // log server errors
    if s.LogErrors {
        serverOpts = append(serverOpts, httptransport.ServerErrorLogger(logger))
    }

    // If any custom middlewares are passed include them
    if len(s.Middlewares) > 0 {
        middlewares = append(middlewares, s.Middlewares...)
    }

    // If any server options are passed include them in server creation
    if len(s.ServerOptions) > 0 {
        serverOpts = append(serverOpts, s.ServerOptions...)
    }

    return middlewares, serverOpts
}
`,

	"zipkin": `package kitworker

import (
    "strings"
    "time"

    "github.com/go-kit/kit/log"
    "github.com/go-kit/kit/tracing/zipkin"
)

type ZipkinConf struct {
    // Address holds Zipkin Host Address, should be a TCP endpoint of the form
    // "host:port".
    Address       string

    // Timeout is passed to the Thrift dial function NewTSocketFromAddrTimeout.
    Timeout       time.Duration

    // BatchSize and batchInterval control the maximum size and interval of a
    // batch of spans as soon as either limit is reached, the batch is sent.
    BatchSize     int
    BatchInterval time.Duration
}

// NewZipkinCollector creates a new Zipkin based ScribeCollector as tracing data
// collector
func NewZipkinCollector(c *ZipkinConf, logger log.Logger) (zipkin.Collector, error) {
    tracingLogger := log.NewContext(logger).With("component", "tracing")
    zipkinLogger := log.NewContext(tracingLogger).With("component", "zipkin")

    if int64(c.Timeout) == 0 {
        c.Timeout = time.Second
    }

    if (c.BatchInterval) == 0 {
        c.BatchInterval = time.Second
    }

    if c.BatchSize == 0 {
        c.BatchSize = 10
    }

    return zipkin.NewScribeCollector(
        c.Address,
        c.Timeout,
        zipkin.ScribeBatchSize(c.BatchSize),
        zipkin.ScribeBatchInterval(c.BatchInterval),
        zipkin.ScribeLogger(zipkinLogger),
    )
}

// NewLoggingCollector creates a tracer which only logs to given logger
func NewLoggingCollector(logger log.Logger) loggingCollector {
    return loggingCollector{logger}
}

type loggingCollector struct{ log.Logger }

// Collect implements Collector interface
func (c loggingCollector) Collect(s *zipkin.Span) error {
    annotations := s.Encode().GetAnnotations()
    values := make([]string, len(annotations))
    for i, a := range annotations {
        values[i] = a.Value
    }
    _ = c.Logger.Log(
        "trace_id", s.TraceID(),
        "span_id", s.SpanID(),
        "parent_span_id", s.ParentSpanID(),
        "annotations", strings.Join(values, " "),
    )
    return nil
}
`,
	"metrics": `package kitworker

import (
    "io"
    "net"
    "sync"
    "time"

    "github.com/go-kit/kit/metrics"
    kitdogstatsd "github.com/go-kit/kit/metrics/dogstatsd"
)

var ReportInterval = time.Second * 30

func NewUDPWriter(addr string) (io.Writer, error) {
    udpAddr, err := net.ResolveUDPAddr("udp", addr)
    if err != nil {
        return nil, err
    }
    conn, err := net.DialUDP("udp", nil, udpAddr)
    if err != nil {
        return nil, err
    }

    return conn, nil
}

type metric struct {
    w            io.Writer
    tags         []metrics.Field
    reportTicker <-chan time.Time

    // metrics registry
    counters   map[string]metrics.Counter
    gauges     map[string]metrics.Gauge
    histograms map[string]metrics.Histogram
    mu         sync.Mutex
}

func NewMetric(addr string, tags ...metrics.Field) (*metric, error) {
    w, err := NewUDPWriter(addr)
    if err != nil {
        return nil, err
    }

    return &metric{
        w:            w,
        tags:         tags,
        reportTicker: time.Tick(ReportInterval),

        counters:   make(map[string]metrics.Counter),
        gauges:     make(map[string]metrics.Gauge),
        histograms: make(map[string]metrics.Histogram),
    }, nil
}

func (m *metric) Counter(key string, tags ...metrics.Field) metrics.Counter {
    m.mu.Lock()
    counter, ok := m.counters[key]
    if !ok {
        counter = kitdogstatsd.NewCounterTick(m.w, key, m.reportTicker, append(m.tags, tags...))
        m.counters[key] = counter
    }
    m.mu.Unlock()

    return counter
}

func (m *metric) DeleteCounter(key string) {
    m.mu.Lock()
    delete(m.counters, key)
    m.mu.Unlock()
}

func (m *metric) Gauge(key string, tags ...metrics.Field) metrics.Gauge {
    m.mu.Lock()
    gauge, ok := m.gauges[key]
    if !ok {
        gauge = kitdogstatsd.NewGaugeTick(m.w, key, m.reportTicker, append(m.tags, tags...))
        m.gauges[key] = gauge
    }
    m.mu.Unlock()

    return gauge
}

func (m *metric) DeleteGauge(key string) {
    m.mu.Lock()
    delete(m.gauges, key)
    m.mu.Unlock()
}

func (m *metric) Histogram(key string, tags ...metrics.Field) metrics.Histogram {
    m.mu.Lock()
    histogram, ok := m.histograms[key]
    if !ok {
        histogram = kitdogstatsd.NewHistogramTick(m.w, key, m.reportTicker, append(m.tags, tags...))
        m.histograms[key] = histogram
    }
    m.mu.Unlock()

    return histogram
}

func (m *metric) DeleteHistogram(key string) {
    m.mu.Lock()
    delete(m.histograms, key)
    m.mu.Unlock()
}
`,
}
