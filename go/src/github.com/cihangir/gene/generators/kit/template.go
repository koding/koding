package kit

// InstrumentingTemplate
var InstrumentingTemplate = `
package kitworker

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
func DefaultMiddlewares(method string, requestCount metrics.Counter, requestLatency metrics.TimeHistogram, logger log.Logger) endpoint.Middleware {
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
func RequestLatencyMiddleware(method string, requestLatency metrics.TimeHistogram) endpoint.Middleware {
	return func(next endpoint.Endpoint) endpoint.Endpoint {
		return func(ctx context.Context, request interface{}) (response interface{}, err error) {
			defer func(begin time.Time) {
				methodField := metrics.Field{Key: "method", Value: method}
				errorField := metrics.Field{Key: "error", Value: fmt.Sprintf("%v", err)}
				requestLatency.With(methodField).With(errorField).Observe(time.Since(begin))
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
`

// InterfaceTemplate
var InterfaceTemplate = `
{{$schema := .Schema}}
{{$title := ToUpperFirst .Schema.Title}}

package {{ToLower $title}}

const ServiceName = "{{ToLower $title}}"

{{AsComment $schema.Description}} type {{$title}}Service interface { {{range $funcKey, $funcValue := $schema.Functions}}
{{AsComment $funcValue.Description}} {{$funcKey}}(ctx context.Context, req *{{Argumentize $funcValue.Properties.incoming}}) (res *{{Argumentize $funcValue.Properties.outgoing}}, err error)
{{end}}
}
`

// Service Template
var ServiceTemplate = `
{{$schema := .Schema}}
{{$title := ToUpperFirst .Schema.Title}}

package {{ToLower $title}}

type {{ToLower $title}} struct{}

func New{{$title}}() {{$title}}Service {
	return &{{ToLower $title}}{}
}

{{range $funcKey, $funcValue := $schema.Functions}}
{{AsComment $funcValue.Description}}func ({{Pointerize $title}} *{{ToLower $title}}) {{$funcKey}}(ctx context.Context, req *{{Argumentize $funcValue.Properties.incoming}}) (*{{Argumentize $funcValue.Properties.outgoing}}, error) {
	return nil, nil
}{{end}}`

// TransportHTTPServerTemplate
var TransportHTTPServerTemplate = `
{{$schema := .Schema}}
{{$title := ToUpperFirst .Schema.Title}}


package {{ToLower $title}}

import (
	"golang.org/x/net/context"

	"github.com/go-kit/kit/endpoint"
	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/metrics"
	"github.com/go-kit/kit/tracing/zipkin"
	httptransport "github.com/go-kit/kit/transport/http"
)


// RegisterHandlers registers handlers of {{$title}}Service to the
// http.DefaultServeMux
func RegisterHandlers(ctx context.Context, svc {{$title}}Service, serverOpts *kitworker.ServerOption, logger log.Logger) { {{range $funcKey, $funcValue := $schema.Functions}}
	http.Handle(New{{$funcKey}}Handler(ctx, svc, serverOpts, logger)){{end}}
}

{{range $funcKey, $funcValue := $schema.Functions}}
{{AsComment $funcValue.Description}}func New{{$funcKey}}Handler(ctx context.Context, svc {{$title}}Service, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointName{{$funcKey}}])
}
{{end}}

func newServer(ctx context.Context, svc {{$title}}Service, opts *kitworker.ServerOption, logger log.Logger, s semiotic) (string, *httptransport.Server) {
	transportLogger := log.NewContext(logger).With("transport", "HTTP/JSON")
	middlewares, serverOpts := opts.Configure(ServiceName, s.Name, transportLogger)

	endpoint := s.ServerEndpointFunc(svc)

	for _, middleware := range middlewares {
		endpoint = middleware(endpoint)
	}

	handler := httptransport.NewServer(
		ctx,
		endpoint,
		s.DecodeRequestFunc,
		s.EncodeResponseFunc,
		serverOpts...,
	)

	return s.Route, handler
}
`

// TransportHTTPClientTemplate
var TransportHTTPClientTemplate = `
{{$schema := .Schema}}
{{$title := ToUpperFirst .Schema.Title}}


package {{ToLower $title}}

import (
	"io"
	"net/url"
	"strings"

	"github.com/go-kit/kit/circuitbreaker"
	"github.com/go-kit/kit/endpoint"
	"github.com/go-kit/kit/loadbalancer"
	"github.com/go-kit/kit/loadbalancer/static"
	"github.com/go-kit/kit/log"
	kitratelimit "github.com/go-kit/kit/ratelimit"
	"github.com/go-kit/kit/tracing/zipkin"
	httptransport "github.com/go-kit/kit/transport/http"
	"github.com/juju/ratelimit"
	jujuratelimit "github.com/juju/ratelimit"
	"github.com/sony/gobreaker"
	"golang.org/x/net/context"
)

// {{$title}}Client holds remote endpoint functions
// Satisfies {{$title}}Service interface
type {{$title}}Client struct {
	{{range $funcKey, $funcValue := $schema.Functions}}// {{$funcKey}}LoadBalancer provides remote call to {{ToLower $funcKey}} endpoints
		{{$funcKey}}LoadBalancer loadbalancer.LoadBalancer

	{{end}}
}

// New{{$title}}Client creates a new client for {{$title}}Service
func  New{{$title}}Client(clientOpts *kitworker.ClientOption, logger log.Logger) *{{$title}}Client {
	if clientOpts.LoadBalancerCreator == nil {
		panic("LoadBalancerCreator must be set")
	}

	return &{{$title}}Client{ {{range $funcKey, $funcValue := $schema.Functions}}
		{{$funcKey}}LoadBalancer : createClientLoadBalancer(semiotics[EndpointName{{$funcKey}}], clientOpts, logger),{{end}}
	}
}

{{range $funcKey, $funcValue := $schema.Functions}}
{{AsComment $funcValue.Description}}func ({{Pointerize $title}} *{{$title}}Client) {{$funcKey}}(ctx context.Context, req *{{Argumentize $funcValue.Properties.incoming}}) (*{{Argumentize $funcValue.Properties.outgoing}}, error) {
	endpoint, err := {{Pointerize $title}}.{{$funcKey}}LoadBalancer.Endpoint()
	if err != nil {
		return nil, err
	}

	res, err := endpoint(ctx, req)
	if err != nil {
		return nil, err
	}

	return res.(*{{Argumentize $funcValue.Properties.outgoing}}), nil
}
{{end}}


func createClientLoadBalancer(
	s semiotic,
	clientOpts *kitworker.ClientOption,
	logger log.Logger,
) loadbalancer.LoadBalancer {
	middlewares, transportOpts := clientOpts.Configure(ServiceName, s.Name)

	loadbalancerFactory := func(instance string) (endpoint.Endpoint, io.Closer, error) {

		e := httptransport.NewClient(
			s.Method,
			kitworker.CreateProxyURL(instance, s.Route),
			s.EncodeRequestFunc,
			s.DecodeResponseFunc,
			transportOpts...,
		).Endpoint()

		for _, middleware := range middlewares {
			e = middleware(e)
		}

		return e, nil, nil
	}

	return clientOpts.LoadBalancerCreator(loadbalancerFactory)
}
`

// TransportHTTPSemioticsTemplate
var TransportHTTPSemioticsTemplate = `
{{$schema := .Schema}}
{{$title := ToUpperFirst .Schema.Title}}


package {{ToLower $title}}

import (
    "io"
    "net/url"
    "strings"

    "github.com/cihangir/gene/example/tinder/models"
    "github.com/go-kit/kit/circuitbreaker"
    "github.com/go-kit/kit/endpoint"
    "github.com/go-kit/kit/loadbalancer"
    "github.com/go-kit/kit/loadbalancer/static"
    "github.com/go-kit/kit/log"
    kitratelimit "github.com/go-kit/kit/ratelimit"
    "github.com/go-kit/kit/tracing/zipkin"
    httptransport "github.com/go-kit/kit/transport/http"
    "github.com/juju/ratelimit"
    jujuratelimit "github.com/juju/ratelimit"
    "github.com/sony/gobreaker"
    "golang.org/x/net/context"
)

const (
{{range $funcKey, $funcValue := $schema.Functions}}
 	EndpointName{{$funcKey}} = "{{ToLower $funcKey}}"{{end}}
)

type semiotic struct {
	Name               string
	Method             string
	Route              string
	ServerEndpointFunc func(svc {{$title}}Service) endpoint.Endpoint
	DecodeRequestFunc  httptransport.DecodeRequestFunc
	EncodeRequestFunc  httptransport.EncodeRequestFunc
	EncodeResponseFunc httptransport.EncodeResponseFunc
	DecodeResponseFunc httptransport.DecodeResponseFunc
}


var semiotics = map[string]semiotic{
{{range $funcKey, $funcValue := $schema.Functions}}
    EndpointName{{$funcKey}}: semiotic{
    	Name:               EndpointName{{$funcKey}},
    	Method:             "POST",
    	ServerEndpointFunc: make{{$funcKey}}Endpoint,
		Route:              "/"+EndpointName{{$funcKey}},
		DecodeRequestFunc:  decode{{$funcKey}}Request,
		EncodeRequestFunc:  encodeRequest,
		EncodeResponseFunc: encodeResponse,
		DecodeResponseFunc: decode{{$funcKey}}Response,
    },
    {{end}}
}

// Decode Request functions

{{range $funcKey, $funcValue := $schema.Functions}}
func decode{{$funcKey}}Request(r *http.Request) (interface{}, error) {
	var req {{Argumentize $funcValue.Properties.incoming}}
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		return nil, err
	}
	return &req, nil
}
{{end}}

// Decode Response functions

{{range $funcKey, $funcValue := $schema.Functions}}
func decode{{$funcKey}}Response(r *http.Response) (interface{}, error) {
	var res {{Argumentize $funcValue.Properties.incoming}}
	if err := json.NewDecoder(r.Body).Decode(&res); err != nil {
		return nil, err
	}
	return &res, nil
}
{{end}}

// Encode request function

func encodeRequest(r *http.Request, request interface{}) error {
	var buf bytes.Buffer
	if err := json.NewEncoder(&buf).Encode(request); err != nil {
		return err
	}
	r.Body = ioutil.NopCloser(&buf)
	return nil
}

// Encode response function

func encodeResponse(rw http.ResponseWriter, response interface{}) error {
	return json.NewEncoder(rw).Encode(response)
}

// Endpoint functions

{{range $funcKey, $funcValue := $schema.Functions}}
func make{{$funcKey}}Endpoint(svc {{$title}}Service) endpoint.Endpoint {
	return func(ctx context.Context, request interface{}) (interface{}, error) {
		req := request.(*{{Argumentize $funcValue.Properties.incoming}})
		return svc.{{$funcKey}}(ctx, req)
	}
}
{{end}}
`
