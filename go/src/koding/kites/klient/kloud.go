package main

import (
	"fmt"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
	"github.com/koding/kloud"
)

// Kloud represents a remote kloud instance
type Kloud struct {
	client *kite.Client
}

// Kloud returns a new connected kloud instance. The kloud is ready to use.
// It's connected and will redial if there is any disconnections.
func NewKloud(k *kite.Kite) (*Kloud, error) {
	kontrolQuery := protocol.KontrolQuery{
		Username:    "koding",
		Environment: "vagrant",
		Name:        "kloud",
	}

	timeout := time.After(time.Minute)

	k.Log.Info("Querying for Kloud: %+v", kontrolQuery)
	for {
		select {
		case <-time.Tick(time.Second * 2):
			kites, err := k.GetKites(kontrolQuery)
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

			// Kloud connection is ready now
			return &Kloud{
				client: remoteKite,
			}, nil
		case <-timeout:
			return nil, fmt.Errorf("timeout while connection for kite")
		}
	}
}

// Report reports machine and usage metrics to a random kloud.
func (k *Kloud) Report() error {
	resp, err := k.client.Tell("report")
	if err != nil {
		return err
	}

	fmt.Printf("resp.MustString() %+v\n", resp.MustString())
	return nil
}
