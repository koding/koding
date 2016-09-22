package stack

import (
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

// TODO(rjeczalik): merge kloud, stack and stackplan packages into one,
// to avoid current issues with cyclic imports and leaky abstractions.

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
	Stack(context.Context) (Stacker, error)

	// Machine returns a value that implements the Machine interface.
	//
	// The Machine interface is used to control a single vm
	// for the specific cloud-provider.
	Machine(ctx context.Context, id string) (Machiner, error)
}

// Stacker is a copy of stackplan.Stack interface, duplicated here
// to avoid cyclic imports.
type Stacker interface {
	VerifyCredential(credential interface{}) error
	BootstrapTemplates(credential interface{}) ([]*Template, error)
	BuildResources() error
	BuildMetadata(*Machine) interface{}
	HandleApply(context.Context) (interface{}, error)
	HandleAuthenticate(context.Context) (interface{}, error)
	HandleBootstrap(context.Context) (interface{}, error)
	HandlePlan(context.Context) (interface{}, error)
}

// Machiner is a copy of stackplan.Machine interface, duplicated here
// to avoid cyclic imports.
type Machiner interface {
	Start(context.Context) error
	Stop(context.Context) error
	Info(context.Context) (*InfoResponse, error)
	State() machinestate.State
	ProviderName() string
}
