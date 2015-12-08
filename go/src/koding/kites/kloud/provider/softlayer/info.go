package softlayer

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"strings"
	"time"

	"github.com/koding/kite"

	"golang.org/x/net/context"
)

func (m *Machine) Info(ctx context.Context) (map[string]string, error) {
	dbState := m.State()
	resultState := dbState
	reason := "not known yet"

	// return lazily if it's a progress state, such as "Building, Stopping,
	// etc.."
	if dbState.InProgress() {
		return map[string]string{
			"State": dbState.String(),
		}, nil
	}

	defer func() {
		// Update db state if the up-to-date state is different than the db.
		if resultState != dbState {
			m.Log.Info("Info decision: Inconsistent state between the machine and db document. Updating state to '%s'. Reason: %s",
				resultState, reason)

			if err := modelhelper.CheckAndUpdateState(m.ObjectId, resultState); err != nil {
				m.Log.Debug("Info decision: Error while updating the machine state. Err: %v", m.ObjectId, err)
			}
		}
	}()

	svc, err := m.Session.SLClient.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return nil, err
	}

	meta, err := m.GetMeta()
	if err != nil {
		return nil, err
	}

	// get final information, such as public IP address and co
	state, err := svc.GetPowerState(meta.Id)
	if err == nil {
		resultState, err = statusToState(state.Name)
		if err != nil {
			return nil, err
		}

		// we don't care about already terminated VM's in AWS provider
		if resultState == machinestate.Terminating {
			resultState = machinestate.Terminated
		}
	} else {
		// if it's something else, return it back
		return nil, err
	}

	if resultState == machinestate.Running {
		// Check if klient is running first.
		klientRef, err := klient.ConnectTimeout(m.Session.Kite, m.QueryString, time.Second*10)
		if err == nil {
			// we could connect to it, which is more than enough
			klientRef.Close()

			reason = "Klient is active and healthy."
			resultState = machinestate.Running

			return map[string]string{
				"State": resultState.String(),
			}, nil
		}

		if err == klient.ErrDialingFailed || err == kite.ErrNoKitesAvailable {
			// klient state is still machinestate.Unknown.
			m.Log.Debug("Klient is not registered to Kontrol. Err: %s", err)

			// XXX: AWS call reduction workaround.
			if dbState == machinestate.Stopped {
				m.Log.Debug("Info result: Returning db state '%s' because the klient is not available. Username: %s",
					dbState, m.Username)
				return map[string]string{
					"State": machinestate.Stopped.String(),
				}, nil
			}
		}
	}

	// m.Log.Debug("Info result: '%s'. Username: %s", resultState, m.Username)
	return map[string]string{
		"State": resultState.String(),
	}, nil
}

func statusToState(status string) (machinestate.State, error) {
	switch strings.ToLower(strings.TrimSpace(status)) {
	case "running":
		return machinestate.Running, nil
	case "halted":
		return machinestate.Stopped, nil
	default:
		return machinestate.Unknown, fmt.Errorf("softlayer state '%s' is unknown", status)
	}
}
