package profile

import (
	"io"

	"github.com/cihangir/gene/example/tinder/models"
	"github.com/cihangir/gene/example/tinder/workers/kitworker"
	"github.com/go-kit/kit/endpoint"
	"github.com/go-kit/kit/loadbalancer"
	"github.com/go-kit/kit/log"
	httptransport "github.com/go-kit/kit/transport/http"
	"golang.org/x/net/context"
)

// ProfileClient holds remote endpoint functions
// Satisfies ProfileService interface
type ProfileClient struct {
	// CreateLoadBalancer provides remote call to create endpoints
	CreateLoadBalancer loadbalancer.LoadBalancer

	// DeleteLoadBalancer provides remote call to delete endpoints
	DeleteLoadBalancer loadbalancer.LoadBalancer

	// MarkAsLoadBalancer provides remote call to markas endpoints
	MarkAsLoadBalancer loadbalancer.LoadBalancer

	// OneLoadBalancer provides remote call to one endpoints
	OneLoadBalancer loadbalancer.LoadBalancer

	// UpdateLoadBalancer provides remote call to update endpoints
	UpdateLoadBalancer loadbalancer.LoadBalancer
}

// NewProfileClient creates a new client for ProfileService
func NewProfileClient(clientOpts *kitworker.ClientOption, logger log.Logger) *ProfileClient {
	if clientOpts.LoadBalancerCreator == nil {
		panic("LoadBalancerCreator must be set")
	}

	return &ProfileClient{
		CreateLoadBalancer: createClientLoadBalancer(semiotics[EndpointNameCreate], clientOpts, logger),
		DeleteLoadBalancer: createClientLoadBalancer(semiotics[EndpointNameDelete], clientOpts, logger),
		MarkAsLoadBalancer: createClientLoadBalancer(semiotics[EndpointNameMarkAs], clientOpts, logger),
		OneLoadBalancer:    createClientLoadBalancer(semiotics[EndpointNameOne], clientOpts, logger),
		UpdateLoadBalancer: createClientLoadBalancer(semiotics[EndpointNameUpdate], clientOpts, logger),
	}
}

// Create creates a new profile on the system with given profile data.
func (p *ProfileClient) Create(ctx context.Context, req *models.Profile) (*models.Profile, error) {
	endpoint, err := p.CreateLoadBalancer.Endpoint()
	if err != nil {
		return nil, err
	}

	res, err := endpoint(ctx, req)
	if err != nil {
		return nil, err
	}

	return res.(*models.Profile), nil
}

// Delete deletes the profile from the system with given profile id. Deletes are
// soft.
func (p *ProfileClient) Delete(ctx context.Context, req *int64) (*models.Profile, error) {
	endpoint, err := p.DeleteLoadBalancer.Endpoint()
	if err != nil {
		return nil, err
	}

	res, err := endpoint(ctx, req)
	if err != nil {
		return nil, err
	}

	return res.(*models.Profile), nil
}

// MarkAs marks given account with given type constant, will be used mostly for
// marking as bot.
func (p *ProfileClient) MarkAs(ctx context.Context, req *models.MarkAsRequest) (*models.Profile, error) {
	endpoint, err := p.MarkAsLoadBalancer.Endpoint()
	if err != nil {
		return nil, err
	}

	res, err := endpoint(ctx, req)
	if err != nil {
		return nil, err
	}

	return res.(*models.Profile), nil
}

// One returns the respective account with the given ID.
func (p *ProfileClient) One(ctx context.Context, req *int64) (*models.Profile, error) {
	endpoint, err := p.OneLoadBalancer.Endpoint()
	if err != nil {
		return nil, err
	}

	res, err := endpoint(ctx, req)
	if err != nil {
		return nil, err
	}

	return res.(*models.Profile), nil
}

// Update updates a new profile on the system with given profile data.
func (p *ProfileClient) Update(ctx context.Context, req *models.Profile) (*models.Profile, error) {
	endpoint, err := p.UpdateLoadBalancer.Endpoint()
	if err != nil {
		return nil, err
	}

	res, err := endpoint(ctx, req)
	if err != nil {
		return nil, err
	}

	return res.(*models.Profile), nil
}

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
