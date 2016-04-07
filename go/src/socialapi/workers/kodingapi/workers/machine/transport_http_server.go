package machine

import (
	"net/http"
	"socialapi/workers/kodingapi/workers/kitworker"

	"golang.org/x/net/context"

	"github.com/go-kit/kit/log"
	httptransport "github.com/go-kit/kit/transport/http"
)

// RegisterHandlers registers handlers of MachineService to the
// http.DefaultServeMux
func RegisterHandlers(ctx context.Context, svc MachineService, serverOpts *kitworker.ServerOption, logger log.Logger) {
	http.Handle(NewGetMachineHandler(ctx, svc, serverOpts, logger))
	http.Handle(NewGetMachineStatusHandler(ctx, svc, serverOpts, logger))
	http.Handle(NewListMachinesHandler(ctx, svc, serverOpts, logger))
}

// GetMachine returns the machine.
func NewGetMachineHandler(ctx context.Context, svc MachineService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameGetMachine])
}

// GetMachineStatus returns the machine's current status.
func NewGetMachineStatusHandler(ctx context.Context, svc MachineService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameGetMachineStatus])
}

// ListMachines returns the machine list of the user.
func NewListMachinesHandler(ctx context.Context, svc MachineService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameListMachines])
}

func newServer(ctx context.Context, svc MachineService, opts *kitworker.ServerOption, logger log.Logger, s semiotic) (string, *httptransport.Server) {
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
