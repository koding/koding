package kloud

import (
	"errors"
	"fmt"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
)

// Klient represents a remote klient instance
type Klient struct {
	client *kite.Client
}

// Klient returns a new connected klient instance to the given queryString. The
// klient is ready to use. It's connected and will redial if there is any
// disconnections.
func (k *Kloud) Klient(queryString string) (*Klient, error) {
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

	klient := &Klient{}

	checkKite := func() error {
		kites, err := k.Kite.GetKites(kontrolQuery)
		if err != nil {
			return err
		}

		remoteKite := kites[0]

		connected, err := remoteKite.DialForever()
		if err != nil {
			return err
		}

		select {
		case <-connected:
		case <-time.After(time.Minute):
			return errors.New("couldn't connect to remote klient kite")
		}

		// klient connection is ready
		klient.client = remoteKite
		return nil
	}

	tryUntil := time.Now().Add(time.Minute)
	for {
		if err = checkKite(); err == nil {
			return klient, nil
		}

		if time.Now().After(tryUntil) {
			return nil, fmt.Errorf("Timeout while waiting for kite. Reason: %v", err)
		}

		time.Sleep(time.Second * 2)
	}
	return nil, err
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
