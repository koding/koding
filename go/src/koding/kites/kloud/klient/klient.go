// Package klient provides an instance and abstraction to a remote klient kite.
// It is used to easily call methods of a klient kite
package klient

import (
	"fmt"
	"koding/kite-handler/command"
	"koding/kites/klient/usage"
	"sync"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
	"github.com/koding/logging"
)

// KlientPool represents a pool of connected klients
type KlientPool struct {
	kite    *kite.Kite
	klients map[string]*Klient
	log     logging.Logger
	sync.Mutex
}

// Klient represents a remote klient instance
type Klient struct {
	client   *kite.Client
	kite     *kite.Kite
	Username string
}

func NewPool(k *kite.Kite) *KlientPool {
	return &KlientPool{
		kite:    k,
		klients: make(map[string]*Klient),
		log:     logging.NewLogger("klientpool"),
	}
}

// Get returns a ready to use and connected klient from the pool.
func (k *KlientPool) Get(queryString string) (*Klient, error) {
	var klient *Klient
	var ok bool
	var err error

	k.Lock()
	defer k.Unlock()

	klient, ok = k.klients[queryString]
	if !ok {
		klient, err = Connect(k.kite, queryString)
		if err != nil {
			return nil, err
		}

		k.log.Info("creating new klient connection to %s", queryString)
		k.klients[queryString] = klient

		// remove from the pool if we loose the connection
		klient.client.OnDisconnect(func() {
			k.log.Info("klient %s disconnected. removing from the pool", queryString)
			k.Delete(queryString)
			klient.Close()
		})
	} else {
		k.log.Debug("fetching already connected klient (%s) from pool", queryString)
	}

	return klient, nil
}

// Delete removes the klient with the given queryString from the pool
func (k *KlientPool) Delete(queryString string) {
	k.Lock()
	defer k.Unlock()

	delete(k.klients, queryString)
}

// Exists checks whether the given queryString exists in Kontrol or not
func Exists(k *kite.Kite, queryString string) error {
	query, err := protocol.KiteFromString(queryString)
	if err != nil {
		return err
	}

	k.Log.Debug("Querying for Klient: %s", queryString)

	// an error indicates a non existing klient or another error.
	_, err = k.GetKites(query.Query())
	if err != nil {
		return err
	}

	return nil
}

// Connect returns a new connected klient instance to the given queryString. The
// klient is ready to use. It's connected and needs to be closed once the task
// is finished with it.
func Connect(k *kite.Kite, queryString string) (*Klient, error) {
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
			if klient, err := Connect(k, queryString); err == nil {
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

// Exec runs a shell command on remote klient machinek
func (k *Klient) Exec(cmd string) (*command.Output, error) {
	var params = struct {
		Command string
	}{
		Command: cmd,
	}

	resp, err := k.client.Tell("exec", params)
	if err != nil {
		return nil, err
	}

	var out *command.Output
	if err := resp.Unmarshal(&out); err != nil {
		return nil, err
	}

	return out, nil
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
