package client

import (
	"context"
	"time"

	"koding/kites/kloud/klient"
	"koding/klient/machine"

	"github.com/koding/kite"
)

// KiteBuilder implements Builder interface. It creates Kite clients that use
// kite query string as their source address.
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
func (kb *KiteBuilder) Ping(dynAddr DynamicAddrFunc) (machine.Status, machine.Addr, error) {
	addr, err := dynAddr("kite")
	if err != nil {
		return machine.Status{}, machine.Addr{}, err
	}

	if _, err := kb.pool.Get(addr.Value); err != nil {
		return machine.Status{}, machine.Addr{}, err
	}

	return machine.Status{
		State: machine.StateConnected,
		Since: time.Now(),
	}, addr, nil
}

// Build builds new kite client that will connect to machine using provided
// address.
func (kb *KiteBuilder) Build(ctx context.Context, addr machine.Addr) Client {
	k, err := kb.pool.Get(addr.Value)
	if err != nil {
		return NewDisconnected(ctx)
	}

	k.SetContext(ctx)
	return k
}
