package main

import (
	"fmt"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
	"github.com/koding/kloud"
)

// Klient represents a remote klient instance
type Klient struct {
	client *kite.Client
}

// Klient returns a new connected klient instance to the given queryString. The
// klient is ready to use. It's connected and will redial if there is any
// disconnections.
func (k *KodingDeploy) Klient(queryString string) (*Klient, error) {
	query, err := protocol.KiteFromString(queryString)
	if err != nil {
		return nil, err
	}

	kontrolQuery := protocol.KontrolQuery{
		Username:    query.Username,
		ID:          query.ID,
		Hostname:    query.Hostname,
		Name:        query.Name,
		Environment: query.Environment,
		Region:      query.Region,
		Version:     query.Version,
	}

	timeout := time.After(time.Minute)

	k.Log.Info("Querying for Klient: %s", queryString)
	for {
		select {
		case <-time.Tick(time.Second * 2):
			kites, err := k.Kite.GetKites(kontrolQuery)
			if err != nil {
				// still not up, try again until the kite is ready
				continue
			}

			remoteKite := kites[0]

			connected, err := remoteKite.DialForever()
			if err != nil {
				return nil, err
			}

			select {
			case <-connected:
			case <-time.After(time.Minute):
				return nil, kloud.NewError(kloud.ErrNoKiteConnection)
			}

			// klient connection is ready now
			return &Klient{
				client: remoteKite,
			}, nil
		case <-timeout:
			return nil, fmt.Errorf("timeout while connection for kite")
		}
	}

}

// Ping checks if the given klient response with "pong" to the "ping" we send.
// A nil error means a successfull pong result.
func (k *Klient) Ping() error {
	resp, err := k.client.Tell("kite.ping")
	if err != nil {
		return err
	}

	if resp.MustString() == "pong" {
		return nil
	}

	return fmt.Errorf("wrong response %s", resp.MustString())
}
