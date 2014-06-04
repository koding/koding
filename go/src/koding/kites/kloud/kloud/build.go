package kloud

import (
	"fmt"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/machinestate"
	"koding/kites/kloud/kloud/protocol"
	"strconv"
	"time"

	"github.com/koding/kite"
)

type ControlResult struct {
	State   machinestate.State `json:"state"`
	EventId string             `json:"eventId"`
}

var defaultImageName = "koding-klient-0.0.1"

func (k *Kloud) build(r *kite.Request, c *Controller) (interface{}, error) {
	if c.CurrenState == machinestate.Building {
		return nil, ErrBuilding
	}

	if c.CurrenState == machinestate.Unknown {
		return nil, ErrUnknownState
	}

	// if it's something else (stopped, runnning, terminated, ...) it's been
	// already built
	if c.CurrenState != machinestate.NotInitialized {
		return nil, ErrAlreadyInitialized
	}

	k.Storage.UpdateState(c.MachineId, machinestate.Building)

	go func() {
		k.idlock.Get(r.Username).Lock()
		defer k.idlock.Get(r.Username).Unlock()

		status := machinestate.Running
		msg := "Build is finished successfully."

		err := k.buildMachine(r.Username, c)
		if err != nil {
			k.Log.Error("Building machine failed: %s. Machine state is marked as ERROR.\n"+
				"Any other calls are now forbidden until the state is resolved manually.\n"+
				"Args: %v User: %s EventId: %v Previous Events: %s",
				err.Error(), c, r.Username, c.MachineId, c.Eventer)

			status = machinestate.Unknown
			msg = err.Error()
		}

		k.Storage.UpdateState(c.MachineId, status)
		c.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
		})
	}()

	return ControlResult{
		EventId: c.Eventer.Id(),
		State:   machinestate.Building,
	}, nil
}

func (k *Kloud) buildMachine(username string, c *Controller) error {
	imageName := defaultImageName
	if c.ImageName != "" {
		imageName = c.ImageName
	}

	instanceName := username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	if c.InstanceName != "" {
		instanceName = c.InstanceName
	}

	buildOptions := &protocol.MachineOptions{
		MachineId:    c.MachineId,
		Username:     username,
		ImageName:    imageName,
		InstanceName: instanceName,
		Eventer:      c.Eventer,
	}

	msg := fmt.Sprintf("Building process started. Provider '%s'. Build options: %+v",
		c.Provider.Name(), buildOptions)
	k.Log.Info(msg)

	c.Eventer.Push(&eventer.Event{Message: msg, Status: machinestate.Building})

	buildResponse, err := c.Provider.Build(buildOptions)
	if err != nil {
		return err
	}

	return k.Storage.Update(c.MachineId, buildResponse)
}
