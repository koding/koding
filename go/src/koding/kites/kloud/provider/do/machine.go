package do

import (
	"errors"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"

	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack/provider"

	"github.com/cenkalti/backoff"
	"github.com/digitalocean/godo"
	"golang.org/x/net/context"
	"golang.org/x/oauth2"
)

const (
	// The statuses of a DigitalOcean action. The value of this attribute can be
	// one of the following: "in-progress", "completed", or "errored"
	// https://developers.digitalocean.com/documentation/v2/#droplet-actions
	actionErrored   = "errored"
	actionCompleted = "completed"

	// A droplet status string indicates the state of a Droplet instance.
	// This may be "new", "active", "off", or "archive".
	// https://developers.digitalocean.com/documentation/v2/#droplets
	statusNew     = "new"
	statusActive  = "active"
	statusOff     = "off"
	statusArchive = "archive"
)

var (
	_ provider.Machine = (*Machine)(nil)

	// ErrInvalidDropletID is returned if an invalid droplet ID is used
	ErrInvalidDropletID = errors.New("droplet ID is invalid")
)

// Machine is responsible of handling a single DO Droplet
type Machine struct {
	*provider.BaseMachine

	client *godo.Client
}

// newMachine returns a provider.Machine that can be used to manager DO
// droplets.
func newMachine(bm *provider.BaseMachine) (provider.Machine, error) {
	cred, ok := bm.Credential.(*Credential)
	if !ok {
		return nil, errors.New("not a valid DigitalOcean credential")
	}

	oauthClient := oauth2.NewClient(
		oauth2.NoContext,
		oauth2.StaticTokenSource(&oauth2.Token{AccessToken: cred.AccessToken}),
	)

	return &Machine{
		client:      godo.NewClient(oauthClient),
		BaseMachine: bm,
	}, nil
}

// Start starts an existing droplet associated to the machine
func (m *Machine) Start(ctx context.Context) (interface{}, error) {
	dropletID, err := m.DropletID()
	if err != nil {
		return nil, err
	}

	if dropletID == 0 {
		return nil, ErrInvalidDropletID
	}

	action, _, err := m.client.DropletActions.PowerOn(dropletID)
	if err != nil {
		return nil, err
	}

	if err := waitForAction(ctx, m.client, action); err != nil {
		return nil, err
	}

	return nil, nil
}

// Stop stops an existing droplet associated to the machine
func (m *Machine) Stop(ctx context.Context) (interface{}, error) {
	dropletID, err := m.DropletID()
	if err != nil {
		return nil, err
	}

	if dropletID == 0 {
		return nil, ErrInvalidDropletID
	}

	// The preferred way to turn off a Droplet is to attempt a shutdown, with a
	// reasonable timeout, followed by a power off action to ensure the Droplet
	// is off.
	action, _, err := m.client.DropletActions.Shutdown(dropletID)
	if err != nil {
		return nil, err
	}

	if err := waitForAction(ctx, m.client, action); err != nil {
		return nil, err
	}

	action, _, err = m.client.DropletActions.PowerOff(dropletID)
	if err != nil {
		return nil, err
	}

	if err := waitForAction(ctx, m.client, action); err != nil {
		return nil, err
	}

	return nil, nil
}

// Info returns the droplet state
func (m *Machine) Info(context.Context) (machinestate.State, interface{}, error) {
	dropletID, err := m.DropletID()
	if err != nil {
		return machinestate.Unknown, nil, err
	}

	if dropletID == 0 {
		return machinestate.Unknown, nil, ErrInvalidDropletID
	}

	droplet, resp, err := m.client.Droplets.Get(dropletID)
	if err != nil {
		if resp.StatusCode == http.StatusNotFound {
			return machinestate.NotInitialized, nil, nil
		}

		return machinestate.Unknown, nil, err
	}

	return statusToState(droplet.Status), nil, nil
}

// DropletID returns the droplet ID associated for this given machine
func (m *Machine) DropletID() (int, error) {
	metadata, ok := m.BaseMachine.Metadata.(*Metadata)
	if !ok {
		return 0, fmt.Errorf("meta data is not of type do.Metadata: %T",
			m.BaseMachine.Metadata)
	}
	return metadata.DropletID, nil
}

// waitForAction waits for a single action to finish.
func waitForAction(ctx context.Context, client *godo.Client, action *godo.Action) error {
	if action == nil {
		return nil
	}

	// NOTE: if we need debugging, enable the following
	debug := false
	if debug {
		start := time.Now()
		log.Println("waiting for action to finish: ", action.ID)
		defer func() {
			log.Println("done: ", time.Since(start).Seconds())
		}()
	}

	ticker := backoff.NewTicker(backoff.NewExponentialBackOff())
	defer ticker.Stop()
	for {
		select {
		case <-ticker.C:
			var err error
			action, _, err = client.Actions.Get(action.ID)
			if err != nil {
				return err
			}
			if action.Status == actionErrored {
				return errors.New(action.String())
			}
			if action.CompletedAt != nil || action.Status == actionCompleted {
				return nil
			}
		case <-ctx.Done():
			return fmt.Errorf("timed out waiting for action %d to complete", action.ID)
		}
	}
}

// statusToState converts a droplet status to a sensible machinestate.State
// enum.
func statusToState(status string) machinestate.State {
	switch strings.ToLower(status) {
	case statusNew:
		return machinestate.Starting
	case statusActive:
		return machinestate.Running
	case statusOff:
		return machinestate.Stopped
	case statusArchive:
		return machinestate.Terminated
	default:
		return machinestate.Unknown
	}
}
