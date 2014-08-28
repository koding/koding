// Package klient provides an instance and abstraction to a remote klient kite.
// It is used to easily call methods of a klient kite
package klient

import (
	"fmt"
	"koding/kites/klient/usage"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
)

// Klient represents a remote klient instance
type Klient struct {
	client   *kite.Client
	kite     *kite.Kite
	Username string
}

// New returns a new connected klient instance to the given queryString. The
// klient is ready to use. It's connected and will redial if there is any
// disconnections.
func New(k *kite.Kite, queryString string) (*Klient, error) {
	query, err := protocol.KiteFromString(queryString)
	if err != nil {
		return nil, err
	}

	k.Log.Debug("Querying for Klient: %s", queryString)

	kites, err := k.GetKites(query.Query())
	if err != nil {
		return nil, err
	}

	remoteKite := kites[0]
	if err := remoteKite.Dial(); err != nil {
		return nil, err
	}

	// klient connection is ready now
	return &Klient{
		kite:     k,
		client:   remoteKite,
		Username: remoteKite.Username,
	}, nil

}

// Klient returns a new connected klient instance to the given queryString. The
// klient is ready to use. It's tries to connect for the given timeout duration
func NewWithTimeout(k *kite.Kite, queryString string, t time.Duration) (*Klient, error) {
	timeout := time.After(t)

	k.Log.Debug("Querying for Klient: %s", queryString)
	for {
		select {
		case <-time.Tick(time.Second * 2):
			if klient, err := New(k, queryString); err == nil {
				return klient, nil
			}

		case <-timeout:
			return nil, fmt.Errorf("timeout while connection for kite")
		}
	}
}

func (k *Klient) Close() {
	k.client.Close()
}

// Usage calls the usage method of remote and get's the result back
func (k *Klient) Usage() (*usage.Usage, error) {
	resp, err := k.client.Tell(usage.MethodName)
	if err != nil {
		return nil, err
	}

	var usg *usage.Usage
	if err := resp.Unmarshal(&usg); err != nil {
		return nil, err
	}

	return usg, nil
}

// Ping checks if the given klient response with "pong" to the "ping" we send.
// A nil error means a successfull pong result.
func (k *Klient) Ping() error {
	resp, err := k.client.Tell("kite.ping")
	if err != nil {
		return err
	}

	out, err := resp.String()
	if err != nil {
		return err
	}

	if out == "pong" {
		return nil
	}

	return fmt.Errorf("wrong response %s", out)
}
