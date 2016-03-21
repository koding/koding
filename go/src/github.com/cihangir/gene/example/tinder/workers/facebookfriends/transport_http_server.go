package facebookfriends

import (
	"net/http"

	"golang.org/x/net/context"

	"github.com/cihangir/gene/example/tinder/workers/kitworker"
	"github.com/go-kit/kit/log"
	httptransport "github.com/go-kit/kit/transport/http"
)

// RegisterHandlers registers handlers of FacebookFriendsService to the
// http.DefaultServeMux
func RegisterHandlers(ctx context.Context, svc FacebookFriendsService, serverOpts *kitworker.ServerOption, logger log.Logger) {
	http.Handle(NewCreateHandler(ctx, svc, serverOpts, logger))
	http.Handle(NewDeleteHandler(ctx, svc, serverOpts, logger))
	http.Handle(NewMutualsHandler(ctx, svc, serverOpts, logger))
	http.Handle(NewOneHandler(ctx, svc, serverOpts, logger))
}

// Create creates a relationship between two facebook account. This function is
// idempotent
func NewCreateHandler(ctx context.Context, svc FacebookFriendsService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameCreate])
}

// Delete removes friendship.
func NewDeleteHandler(ctx context.Context, svc FacebookFriendsService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameDelete])
}

// Mutuals return mutual friend's Facebook IDs between given source id and
// target id. Source and Target are inclusive.
func NewMutualsHandler(ctx context.Context, svc FacebookFriendsService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameMutuals])
}

// One fetches a FacebookFriends from system with FacebookFriends, will be used
// for validating the existance of the friendship
func NewOneHandler(ctx context.Context, svc FacebookFriendsService, opts *kitworker.ServerOption, logger log.Logger) (string, *httptransport.Server) {
	return newServer(ctx, svc, opts, logger, semiotics[EndpointNameOne])
}

func newServer(ctx context.Context, svc FacebookFriendsService, opts *kitworker.ServerOption, logger log.Logger, s semiotic) (string, *httptransport.Server) {
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
