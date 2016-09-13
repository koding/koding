package awsprovider

import (
	"time"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/koding/kite"
	"golang.org/x/net/context"
)

func (m *Machine) Info(ctx context.Context) (*stack.InfoResponse, error) {
	dbState := m.State()
	resultState := dbState
	reason := "not known yet"

	// return lazily if it's a progress state, such as "Building, Stopping,
	// etc.."
	if dbState.InProgress() {
		return &stack.InfoResponse{
			State: dbState,
		}, nil
	}

	defer func() {
		// Update db state if the up-to-date state is different than the db.
		if resultState != dbState {
			m.Log.Info("Info decision: Inconsistent state between the machine and db document. Updating state to '%s'. Reason: %s",
				resultState, reason)

			if err := modelhelper.CheckAndUpdateState(m.ObjectId, resultState); err != nil {
				m.Log.Debug("Info decision: Error while updating the machine %q state. Err: %v", m.ObjectId, err)
			}
		}
	}()

	instance, err := m.Session.AWSClient.Instance()
	switch {
	case err == nil:
		resultState = amazon.StatusToState(aws.StringValue(instance.State.Name))
		// we don't care about already terminated VM's in AWS provider
		if resultState == machinestate.Terminating {
			resultState = machinestate.Terminated
		}
	case amazon.IsNotFound(err):
		resultState = machinestate.NotInitialized
	default:
		// if it's something else, return it back
		return nil, err
	}

	// This happens when a machine was destroyed recently in one hour span.
	// The machine is still available in AWS but it's been marked as
	// Terminated. Because we still have the machine document, mark it as
	// Terminated so the client side knows what to do
	if resultState == machinestate.Terminated || resultState == machinestate.Terminating {
		if err := modelhelper.ChangeMachineState(m.ObjectId, "Machine was terminated in last one hour span",
			machinestate.Terminated); err != nil {
			return nil, err
		}
	}

	if resultState == machinestate.Running {
		// Check if klient is running first.
		klientRef, err := klient.ConnectTimeout(m.Session.Kite, m.QueryString, time.Second*10)
		if err == nil {
			// we could connect to it, which is more than enough
			klientRef.Close()

			reason = "Klient is active and healthy."
			resultState = machinestate.Running

			return &stack.InfoResponse{
				State: resultState,
			}, nil
		}

		if err == klient.ErrDialingFailed || err == kite.ErrNoKitesAvailable {
			// klient state is still machinestate.Unknown.
			m.Log.Debug("Klient is not registered to Kontrol. Err: %s", err)

			// XXX: AWS call reduction workaround.
			if dbState == machinestate.Stopped {
				m.Log.Debug("Info result: Returning db state '%s' because the klient is not available. Username: %s",
					dbState, m.User.Name)
				return &stack.InfoResponse{
					State: machinestate.Stopped,
				}, nil
			}
		}
	}

	m.Log.Debug("Info result: '%s'. Username: %s", resultState, m.User.Name)
	return &stack.InfoResponse{
		State: resultState,
	}, nil
}
