package kit

import (
	"encoding/json"

	"testing"

	"github.com/cihangir/gene/generators/common"
	"github.com/cihangir/gene/testdata"
	"github.com/cihangir/schema"
)

func TestTransportHTTPServer(t *testing.T) {
	s := &schema.Schema{}
	err := json.Unmarshal([]byte(testdata.TestDataFull), s)

	s = s.Resolve(s)

	sts, err := GenerateTransportHTTPServer(common.NewContext(), s)
	common.TestEquals(t, nil, err)
	common.TestEquals(t, transportHTTPServerExpecteds[0], string(sts[0].Content))
}

var transportHTTPServerExpecteds = []string{`package account

import (
	"golang.org/x/net/context"

	"github.com/go-kit/kit/endpoint"
	"github.com/go-kit/kit/log"
	"github.com/go-kit/kit/metrics"
	"github.com/go-kit/kit/tracing/zipkin"
	httptransport "github.com/go-kit/kit/transport/http"
)

// RegisterHandlers registers handlers of AccountService to the
// http.DefaultServeMux
func RegisterHandlers(ctx context.Context, svc AccountService, serverOpts *kitworker.ServerOption, logger log.Logger) {
	http.Handle(NewCreateHandler(ctx, svc, serverOpts, logger))
	http.Handle(NewDeleteHandler(ctx, svc, serverOpts, logger))
	http.Handle(NewOneHandler(ctx, svc, serverOpts, logger))
	http.Handle(NewSomeHandler(ctx, svc, serverOpts, logger))
	http.Handle(NewUpdateHandler(ctx, svc, serverOpts, logger))
}

func NewCreateHandler(ctx context.Context, svc AccountService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameCreate])
}

func NewDeleteHandler(ctx context.Context, svc AccountService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameDelete])
}

func NewOneHandler(ctx context.Context, svc AccountService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameOne])
}

func NewSomeHandler(ctx context.Context, svc AccountService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameSome])
}

func NewUpdateHandler(ctx context.Context, svc AccountService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameUpdate])
}

func newServer(ctx context.Context, svc AccountService, opts *kitworker.ServerOption, logger log.Logger, s semiotic) (string, *httptransport.Server) {
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
`}
