package machine

import (
	"context"
	"time"

	"koding/kites/kloud/klient"

	"github.com/koding/kite"
)

// KiteBuilder implements ClientBuilder interface. It creates Kite clients that
// use kite query string as their source address.
type KiteBuilder struct {
	pool *klient.KlientPool
}

// NewKiteBuilder creates a new KiteBuilder instance.
func NewKiteBuilder(k *kite.Kite) *KiteBuilder {
	return &KiteBuilder{
		pool: klient.NewPool(k),
	}
}

// Ping uses kite network that stores kite's query string to ping the machine.
func (kb *KiteBuilder) Ping(dynAddr DynamicAddrFunc) (Status, Addr, error) {
	addr, err := dynAddr("kite")
	if err != nil {
		return Status{}, Addr{}, err
	}

	if _, err := kb.pool.Get(addr.Value); err != nil {
		return Status{}, Addr{}, err
	}

	return Status{
		State: StateConnected,
		Since: time.Now(),
	}, addr, nil
}

// Build builds new kite client that will connect to machine using provided
// address.
func (kb *KiteBuilder) Build(_ context.Context, addr Addr) Client {
	k, err := kb.pool.Get(addr.Value)
	if err != nil {
		return DisconnectedClient{}
	}

	return k
}
