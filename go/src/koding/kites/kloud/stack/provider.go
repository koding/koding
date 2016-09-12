package stack

import (
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

// Interface provides all kloud methods that a provider can support.
type Interface interface {
	Provider
	Builder
	Destroyer
	Infoer
	Stopper
	Starter
	Reiniter
	Resizer
	Restarter
}

// InfoArtifact should be returned from a Info method.
type InfoArtifact struct {
	// State defines the state of the machine
	State machinestate.State

	// Name defines the name of the machine.
	Name string

	// InstanceType defines the type of the given machine
	InstanceType string
}

// Provider is used to manage architecture for the specific
// cloud provider and to control particular virtual machines
// within it.
//
// Kloud comes with the following built-in providers:
//
//   - aws
//   - vagrant
//
type Provider interface {
	// Stack returns a provider that implements team methods.
	//
	// Team methods are used to manage architecture for
	// the given cloud-provider - they can bootstrap,
	// modify or destroy resources, which can be
	// backed by Terraform-specific provider.
	//
	// The default helper *provider.BaseStack uses
	// Terraform for heavy lifting. Provider-specific
	// implementations are used to augment the user
	// stacks (Terraform templates) with default
	// resources created during bootstrap.
	Stack(context.Context) (Stack, error)

	// Machine returns a value that implements the Machine interface.
	//
	// The Machine interface is used to control a single vm
	// for the specific cloud-provider.
	Machine(ctx context.Context, id string) (Machine, error)

	// Meta returns new value for provider-specific metadata.
	// The Meta is called when building credentials
	// for apply and bootstrap requests, so each provider
	// has access to type-friendly metadata values.
	//
	// Examples:
	//
	//   - aws.AwsMeta
	//   - vagrant.VagrantMeta
	//
	Meta() interface{}
}

// Stack is a provider-specific handler that implements team methods.
type Stack interface {
	Apply(context.Context) (interface{}, error)
	Authenticate(context.Context) (interface{}, error)
	Bootstrap(context.Context) (interface{}, error)
	Plan(context.Context) (interface{}, error)
}

type Machine interface {
	Start(context.Context) error
	Stop(context.Context) error
	Info(context.Context) (map[string]string, error)
}

type Builder interface {
	Build(ctx context.Context) error
}

type Destroyer interface {
	Destroy(ctx context.Context) error
}

type Stopper interface {
	Stop(ctx context.Context) error
}

type Starter interface {
	Start(ctx context.Context) error
}

type Reiniter interface {
	Reinit(ctx context.Context) error
}

type Resizer interface {
	Resize(ctx context.Context) error
}

type Restarter interface {
	Restart(ctx context.Context) error
}

type Infoer interface {
	Info(ctx context.Context) (map[string]string, error)
}

type Snapshotter interface {
	CreateSnapshot(ctx context.Context) error
	DeleteSnapshot(ctx context.Context) error
}

type PublicIpAddressFetcher interface {
	PublicIpAddress() string
}

// Stater returns the state of a machine and the provider name
type Stater interface {
	State() machinestate.State
	ProviderName() string
}
