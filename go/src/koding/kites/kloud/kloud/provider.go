package kloud

import (
	"koding/kites/kloud/machinestate"

	"golang.org/x/net/context"
)

type ctxKey int

const requestKey ctxKey = 0

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

// Stater returns the state of a machine
type Stater interface {
	State() machinestate.State
}
