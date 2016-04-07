package machine

import (
	"fmt"
	"io"
	// "koding/db/models"
	"socialapi/workers/kodingapi/models"
	"socialapi/workers/kodingapi/workers/kitworker"

	"github.com/go-kit/kit/endpoint"
	"github.com/go-kit/kit/loadbalancer"
	"github.com/go-kit/kit/log"
	httptransport "github.com/go-kit/kit/transport/http"
	"golang.org/x/net/context"
)

// MachineClient holds remote endpoint functions
// Satisfies MachineService interface
type MachineClient struct {
	// GetMachineLoadBalancer provides remote call to getmachine endpoints
	GetMachineLoadBalancer loadbalancer.LoadBalancer

	// GetMachineStatusLoadBalancer provides remote call to getmachinestatus endpoints
	GetMachineStatusLoadBalancer loadbalancer.LoadBalancer

	// ListMachinesLoadBalancer provides remote call to listmachines endpoints
	ListMachinesLoadBalancer loadbalancer.LoadBalancer
}

// NewMachineClient creates a new client for MachineService
func NewMachineClient(clientOpts *kitworker.ClientOption, logger log.Logger) *MachineClient {
	if clientOpts.LoadBalancerCreator == nil {
		panic("LoadBalancerCreator must be set")
	}

	return &MachineClient{
		GetMachineLoadBalancer:       createClientLoadBalancer(semiotics[EndpointNameGetMachine], clientOpts, logger),
		GetMachineStatusLoadBalancer: createClientLoadBalancer(semiotics[EndpointNameGetMachineStatus], clientOpts, logger),
		ListMachinesLoadBalancer:     createClientLoadBalancer(semiotics[EndpointNameListMachines], clientOpts, logger),
	}
}

// GetMachine returns the machine.
func (m *MachineClient) GetMachine(ctx context.Context, req *string) (*models.Machine, error) {
	endpoint, err := m.GetMachineLoadBalancer.Endpoint()
	if err != nil {
		fmt.Println("ERR WHILE GETMACHINELOADBALANCER")
		return nil, err
	}
	fmt.Println("CONTEXT IS :",ctx)
	fmt.Println("REQUEST IS IS :",req)
	res, err := endpoint(ctx, req)
	if err != nil {
		fmt.Println("WEE WHILE ENDPOINTS")
		return nil, err
	}

	return res.(*models.Machine), nil
}

// GetMachineStatus returns the machine's current status.
func (m *MachineClient) GetMachineStatus(ctx context.Context, req *string) (*models.Machine, error) {
	endpoint, err := m.GetMachineStatusLoadBalancer.Endpoint()
	if err != nil {
		return nil, err
	}

	res, err := endpoint(ctx, req)
	if err != nil {
		return nil, err
	}

	return res.(*models.Machine), nil
}

// ListMachines returns the machine list of the user.
func (m *MachineClient) ListMachines(ctx context.Context, req *string) (*[]*models.Machine, error) {
	endpoint, err := m.ListMachinesLoadBalancer.Endpoint()
	if err != nil {
		return nil, err
	}

	res, err := endpoint(ctx, req)
	if err != nil {
		return nil, err
	}

	return res.(*[]*models.Machine), nil
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
