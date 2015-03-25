package kloud

import (
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

// InfoArtifact should be returned from a Info method.
type InfoArtifact struct {
	// State defines the state of the machine
	State machinestate.State

	// Name defines the name of the machine.
	Name string

	// InstanceType defines the type of the given machine
	InstanceType string
}

// Provider is responsible of managing and controlling a cloud provider
type Provider interface {
	// Machine returns a machine that should satisfy the necessary
	// interfaces
	Machine(ctx context.Context, id string) (interface{}, error)
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

// Stater returns the state of a machine
type Stater interface {
	State() machinestate.State
}
