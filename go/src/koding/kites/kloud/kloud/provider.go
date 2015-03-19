package kloud

import "golang.org/x/net/context"

// Provider is responsible of managing and controlling a cloud provider
type Provider interface {
	// Get returns a machine that should satisfy the necessary interfaces
	Get(id string) (interface{}, error)
}

type Builder interface {
	Builder(ctx context.Context) error
}

type Artifact interface {
	Values(key string) string
}
