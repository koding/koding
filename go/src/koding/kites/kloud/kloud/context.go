package kloud

import (
	"koding/db/mongodb"
	"koding/kites/kloud/dnsclient"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

type key int

const sessionKey key = 0

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

type Context struct {
	DB   *mongodb.MongoDB
	Kite *kite.Kite
	DNS  *dnsclient.DNS
}

func (k *Kloud) NewContext(ctx context.Context) context.Context {
	return context.WithValue(ctx, sessionKey, &Context{
		DB:   nil,
		Kite: nil,
		DNS:  nil,
	})
}
