package koding

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/koding/kite"
	"golang.org/x/net/context"
)

// Info returns the current State of the given Machine. As an optiminzation,
// Info decides the machine state based on it's ability to communicate
// with Klient.
//
// If Klient cannot be found, the machine will go through the full Stop
// process.
//
// If Klient can be found, the machine is Running.
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

	meta, err := m.GetMeta()
	if err != nil {
		return nil, err
	}

	// On Defer, update db state if the up-to-date state from the
	// provider is different than the state stored in the database.
	defer func() {
		// If the two states are in sync no action is needed.
		if resultState == dbState {
			return
		}

		m.Log.Info("Info decision: Inconsistent state. Database state '%s', updating state to '%s'. Reason: %s",
			dbState.String(), resultState, reason)

		// If the machine's state is being transitioned into Stop, use the
		// normal Stop() method to use a proper shutdown sequence with Kloud.
		// This ensures that the machine will never store Stopped in the
		// database, while still running on the provider.
		if resultState == machinestate.Stopped {
			if meta.AlwaysOn {
				m.Log.Info("Info decision was to stop the machine, but it is an AlwaysOn machine. Ignoring decision. (username: %s, instanceId: %s, region: %s)",
					m.Username, meta.InstanceId, meta.Region,
				)
				return
			}

			m.Log.Info("======> STOP started (inconsistent state)<======")

			// Note that this Stop() call is done in a goroutine so that it
			// does not block the Info() call.
			go func(machine *Machine) {
				// Note that we are ignoring any potential Lock Errors, as
				// we are Forcing the Stop state. In the future we may want to
				// queue the Stop method, to avoid race conditions.
				machine.Lock()
				defer machine.Unlock()

				err := machine.Stop(ctx)
				if err != nil {
					machine.Log.Debug("Info decision: Error while Stopping machine %q. Err: %v",
						machine.ObjectId, err)
				}
				machine.Log.Info("======> STOP finished (inconsistent state)<======")
			}(m)
			return
		}

		if err := modelhelper.CheckAndUpdateState(m.ObjectId, resultState); err != nil {
			m.Log.Debug("Info decision: Error while updating the machine %q state. Err: %v", m.ObjectId, err)
		}
	}()

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

	// We couldn't reach klient, either kontrol is crashed or we couldn't dial
	// to it, and many other problems...
	reason = "Klient is not reachable."
	instance, err := m.Session.AWSClient.Instance()
	switch {
	case err == nil:
		resultState = amazon.StatusToState(aws.StringValue(instance.State.Name))
	case amazon.IsNotFound(err):
		resultState = machinestate.NotInitialized
	default:
		// if it's something else, return it back
		return nil, err
	}

	switch resultState {
	case machinestate.Unknown:
		return nil, fmt.Errorf("Unknown amazon status: %+v. This needs to be fixed.", instance.State)
	case machinestate.Running:
		// this is a case where: 1) klient is unreachable 2) machine is running
		// we don't want to give away our machines without a klient is running on it,
		// so mark and return as stopped.
		resultState = machinestate.Stopped

		if meta.AlwaysOn {
			// machine is always-on. return as running
			resultState = machinestate.Running
		}
	case machinestate.Terminated, machinestate.Terminating:
		// This happens when a machine was destroyed recently in one hour span.
		// The machine is still available in AWS but it's been marked as
		// Terminated. Because we still have the machine document, mark it as
		// NotInitialized so the user can build again.
		resultState = machinestate.NotInitialized

		if err := m.markAsNotInitialized(); err != nil {
			return nil, err
		}
	}

	m.Log.Debug("Info result: '%s'. Username: %s", resultState, m.Username)
	return map[string]string{
		"State": resultState.String(),
	}, nil
}
