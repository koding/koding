package controlapi

import (
	"errors"
	"reflect"

	"github.com/docker/engine-api/types/reference"
	"github.com/docker/swarmkit/api"
	"github.com/docker/swarmkit/identity"
	"github.com/docker/swarmkit/manager/scheduler"
	"github.com/docker/swarmkit/manager/state/store"
	"github.com/docker/swarmkit/protobuf/ptypes"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
)

var (
	errNetworkUpdateNotSupported = errors.New("changing network in service is not supported")
	errModeChangeNotAllowed      = errors.New("service mode change is not allowed")
)

func validateResources(r *api.Resources) error {
	if r == nil {
		return nil
	}

	if r.NanoCPUs != 0 && r.NanoCPUs < 1e6 {
		return grpc.Errorf(codes.InvalidArgument, "invalid cpu value %g: Must be at least %g", float64(r.NanoCPUs)/1e9, 1e6/1e9)
	}

	if r.MemoryBytes != 0 && r.MemoryBytes < 4*1024*1024 {
		return grpc.Errorf(codes.InvalidArgument, "invalid memory value %d: Must be at least 4MiB", r.MemoryBytes)
	}
	return nil
}

func validateResourceRequirements(r *api.ResourceRequirements) error {
	if r == nil {
		return nil
	}
	if err := validateResources(r.Limits); err != nil {
		return err
	}
	if err := validateResources(r.Reservations); err != nil {
		return err
	}
	return nil
}

func validateRestartPolicy(rp *api.RestartPolicy) error {
	if rp == nil {
		return nil
	}

	if rp.Delay != nil {
		delay, err := ptypes.Duration(rp.Delay)
		if err != nil {
			return err
		}
		if delay < 0 {
			return grpc.Errorf(codes.InvalidArgument, "TaskSpec: restart-delay cannot be negative")
		}
	}

	if rp.Window != nil {
		win, err := ptypes.Duration(rp.Window)
		if err != nil {
			return err
		}
		if win < 0 {
			return grpc.Errorf(codes.InvalidArgument, "TaskSpec: restart-window cannot be negative")
		}
	}

	return nil
}

func validatePlacement(placement *api.Placement) error {
	if placement == nil {
		return nil
	}
	_, err := scheduler.ParseExprs(placement.Constraints)
	return err
}

func validateUpdate(uc *api.UpdateConfig) error {
	if uc == nil {
		return nil
	}

	delay, err := ptypes.Duration(&uc.Delay)
	if err != nil {
		return err
	}

	if delay < 0 {
		return grpc.Errorf(codes.InvalidArgument, "TaskSpec: update-delay cannot be negative")
	}

	return nil
}

func validateTask(taskSpec api.TaskSpec) error {
	if err := validateResourceRequirements(taskSpec.Resources); err != nil {
		return err
	}

	if err := validateRestartPolicy(taskSpec.Restart); err != nil {
		return err
	}

	if err := validatePlacement(taskSpec.Placement); err != nil {
		return err
	}

	if taskSpec.GetRuntime() == nil {
		return grpc.Errorf(codes.InvalidArgument, "TaskSpec: missing runtime")
	}

	_, ok := taskSpec.GetRuntime().(*api.TaskSpec_Container)
	if !ok {
		return grpc.Errorf(codes.Unimplemented, "RuntimeSpec: unimplemented runtime in service spec")
	}

	container := taskSpec.GetContainer()
	if container == nil {
		return grpc.Errorf(codes.InvalidArgument, "ContainerSpec: missing in service spec")
	}

	if container.Image == "" {
		return grpc.Errorf(codes.InvalidArgument, "ContainerSpec: image reference must be provided")
	}

	if _, _, err := reference.Parse(container.Image); err != nil {
		return grpc.Errorf(codes.InvalidArgument, "ContainerSpec: %q is not a valid repository/tag", container.Image)
	}
	return nil
}

func validateEndpointSpec(epSpec *api.EndpointSpec) error {
	// Endpoint spec is optional
	if epSpec == nil {
		return nil
	}

	portSet := make(map[api.PortConfig]struct{})
	for _, port := range epSpec.Ports {
		if _, ok := portSet[*port]; ok {
			return grpc.Errorf(codes.InvalidArgument, "EndpointSpec: duplicate ports provided")
		}

		portSet[*port] = struct{}{}
	}

	return nil
}

func validateServiceSpec(spec *api.ServiceSpec) error {
	if spec == nil {
		return grpc.Errorf(codes.InvalidArgument, errInvalidArgument.Error())
	}
	if err := validateAnnotations(spec.Annotations); err != nil {
		return err
	}
	if err := validateTask(spec.Task); err != nil {
		return err
	}
	if err := validateUpdate(spec.Update); err != nil {
		return err
	}
	if err := validateEndpointSpec(spec.Endpoint); err != nil {
		return err
	}
	return nil
}

// CreateService creates and return a Service based on the provided ServiceSpec.
// - Returns `InvalidArgument` if the ServiceSpec is malformed.
// - Returns `Unimplemented` if the ServiceSpec references unimplemented features.
// - Returns `AlreadyExists` if the ServiceID conflicts.
// - Returns an error if the creation fails.
func (s *Server) CreateService(ctx context.Context, request *api.CreateServiceRequest) (*api.CreateServiceResponse, error) {
	if err := validateServiceSpec(request.Spec); err != nil {
		return nil, err
	}

	// TODO(aluzzardi): Consider using `Name` as a primary key to handle
	// duplicate creations. See #65
	service := &api.Service{
		ID:   identity.NewID(),
		Spec: *request.Spec,
	}

	err := s.store.Update(func(tx store.Tx) error {
		return store.CreateService(tx, service)
	})
	if err != nil {
		return nil, err
	}

	return &api.CreateServiceResponse{
		Service: service,
	}, nil
}

// GetService returns a Service given a ServiceID.
// - Returns `InvalidArgument` if ServiceID is not provided.
// - Returns `NotFound` if the Service is not found.
func (s *Server) GetService(ctx context.Context, request *api.GetServiceRequest) (*api.GetServiceResponse, error) {
	if request.ServiceID == "" {
		return nil, grpc.Errorf(codes.InvalidArgument, errInvalidArgument.Error())
	}

	var service *api.Service
	s.store.View(func(tx store.ReadTx) {
		service = store.GetService(tx, request.ServiceID)
	})
	if service == nil {
		return nil, grpc.Errorf(codes.NotFound, "service %s not found", request.ServiceID)
	}

	return &api.GetServiceResponse{
		Service: service,
	}, nil
}

// UpdateService updates a Service referenced by ServiceID with the given ServiceSpec.
// - Returns `NotFound` if the Service is not found.
// - Returns `InvalidArgument` if the ServiceSpec is malformed.
// - Returns `Unimplemented` if the ServiceSpec references unimplemented features.
// - Returns an error if the update fails.
func (s *Server) UpdateService(ctx context.Context, request *api.UpdateServiceRequest) (*api.UpdateServiceResponse, error) {
	if request.ServiceID == "" || request.ServiceVersion == nil {
		return nil, grpc.Errorf(codes.InvalidArgument, errInvalidArgument.Error())
	}
	if err := validateServiceSpec(request.Spec); err != nil {
		return nil, err
	}

	var service *api.Service
	err := s.store.Update(func(tx store.Tx) error {
		service = store.GetService(tx, request.ServiceID)
		if service == nil {
			return nil
		}
		// temporary disable network update
		if request.Spec != nil && !reflect.DeepEqual(request.Spec.Networks, service.Spec.Networks) {
			return errNetworkUpdateNotSupported
		}

		// orchestrator is designed to be stateless, so it should not deal
		// with service mode change (comparing current config with previous config).
		// proper way to change service mode is to delete and re-add.
		if request.Spec != nil && reflect.TypeOf(service.Spec.Mode) != reflect.TypeOf(request.Spec.Mode) {
			return errModeChangeNotAllowed
		}
		service.Meta.Version = *request.ServiceVersion
		service.Spec = *request.Spec.Copy()
		return store.UpdateService(tx, service)
	})
	if err != nil {
		return nil, err
	}
	if service == nil {
		return nil, grpc.Errorf(codes.NotFound, "service %s not found", request.ServiceID)
	}
	return &api.UpdateServiceResponse{
		Service: service,
	}, nil
}

// RemoveService removes a Service referenced by ServiceID.
// - Returns `InvalidArgument` if ServiceID is not provided.
// - Returns `NotFound` if the Service is not found.
// - Returns an error if the deletion fails.
func (s *Server) RemoveService(ctx context.Context, request *api.RemoveServiceRequest) (*api.RemoveServiceResponse, error) {
	if request.ServiceID == "" {
		return nil, grpc.Errorf(codes.InvalidArgument, errInvalidArgument.Error())
	}

	err := s.store.Update(func(tx store.Tx) error {
		return store.DeleteService(tx, request.ServiceID)
	})
	if err != nil {
		if err == store.ErrNotExist {
			return nil, grpc.Errorf(codes.NotFound, "service %s not found", request.ServiceID)
		}
		return nil, err
	}
	return &api.RemoveServiceResponse{}, nil
}

func filterServices(candidates []*api.Service, filters ...func(*api.Service) bool) []*api.Service {
	result := []*api.Service{}

	for _, c := range candidates {
		match := true
		for _, f := range filters {
			if !f(c) {
				match = false
				break
			}
		}
		if match {
			result = append(result, c)
		}
	}

	return result
}

// ListServices returns a list of all services.
func (s *Server) ListServices(ctx context.Context, request *api.ListServicesRequest) (*api.ListServicesResponse, error) {
	var (
		services []*api.Service
		err      error
	)

	s.store.View(func(tx store.ReadTx) {
		switch {
		case request.Filters != nil && len(request.Filters.Names) > 0:
			services, err = store.FindServices(tx, buildFilters(store.ByName, request.Filters.Names))
		case request.Filters != nil && len(request.Filters.NamePrefixes) > 0:
			services, err = store.FindServices(tx, buildFilters(store.ByNamePrefix, request.Filters.NamePrefixes))
		case request.Filters != nil && len(request.Filters.IDPrefixes) > 0:
			services, err = store.FindServices(tx, buildFilters(store.ByIDPrefix, request.Filters.IDPrefixes))
		default:
			services, err = store.FindServices(tx, store.All)
		}
	})
	if err != nil {
		return nil, err
	}

	if request.Filters != nil {
		services = filterServices(services,
			func(e *api.Service) bool {
				return filterContains(e.Spec.Annotations.Name, request.Filters.Names)
			},
			func(e *api.Service) bool {
				return filterContainsPrefix(e.Spec.Annotations.Name, request.Filters.NamePrefixes)
			},
			func(e *api.Service) bool {
				return filterContainsPrefix(e.ID, request.Filters.IDPrefixes)
			},
			func(e *api.Service) bool {
				return filterMatchLabels(e.Spec.Annotations.Labels, request.Filters.Labels)
			},
		)
	}

	return &api.ListServicesResponse{
		Services: services,
	}, nil
}
