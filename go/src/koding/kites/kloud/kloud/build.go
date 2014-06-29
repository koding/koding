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

func (k *Kloud) build(r *kite.Request, c *Controller) (resp interface{}, err error) {
	if c.CurrenState == machinestate.Building {
		return nil, NewError(ErrMachineIsBuilding)
	}

	if c.CurrenState == machinestate.Unknown {
		return nil, NewError(ErrMachineUnknownState)
	}

	// if it's something else (stopped, runnning, ...) it's been already built
	if !c.CurrenState.In(machinestate.Terminated, machinestate.NotInitialized) {
		return nil, NewError(ErrMachineInitialized)
	}

	k.Storage.UpdateState(c.MachineId, machinestate.Building)
	c.Eventer = k.NewEventer(r.Method + "-" + c.MachineId)

	go func() {
		k.idlock.Get(c.MachineId).Lock()
		defer k.idlock.Get(c.MachineId).Unlock()

		status := machinestate.Running
		msg := "Build is finished successfully."

		err := k.buildMachine(r.Username, c)
		if err != nil {
			k.Log.Error("[controller] building machine failed: %s.", err.Error())

			status = c.CurrenState
			msg = err.Error()
		} else {
			k.Log.Info("[%s] is successfull. State is now: %+v", r.Method, status)
		}

		k.Storage.UpdateState(c.MachineId, status)
		k.Storage.ResetAssignee(c.MachineId)
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
	instanceName := username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	if c.InstanceName != "" {
		instanceName = c.InstanceName
	}

	machOptions := &protocol.MachineOptions{
		MachineId:    c.MachineId,
		Username:     username,
		ImageName:    c.ImageName,
		InstanceName: instanceName,
		Eventer:      c.Eventer,
		Credential:   c.MachineData.Credential.Meta,
		Builder:      c.MachineData.Machine.Meta,
	}

	msg := fmt.Sprintf("Building process started. Provider '%s'. Build options: %+v",
		c.Provider.Name(), machOptions)

	c.Eventer.Push(&eventer.Event{Message: msg, Status: machinestate.Building})

	k.Log.Debug("[controller]: running method 'build' with machine options %v", machOptions)
	resp, err := c.Provider.Build(machOptions)
	if err != nil {
		return err
	}
	if resp == nil {
		return NewError(ErrBadResponse)
	}
	k.Log.Debug("[controller]: method 'build' is successfull %#v", resp)

	k.Log.Info("[controller]: deploying klient.deb and setting up machine")
	artifact, err := k.DeployFunc(username, resp.InstanceName, resp.IpAddress)
	if err != nil {
		return err
	}

	return k.Storage.Update(c.MachineId, &StorageData{
		Type: "build",
		Data: map[string]interface{}{
			"queryString":  artifact.KiteQuery,
			"ipAddress":    resp.IpAddress,
			"instanceId":   strconv.Itoa(resp.InstanceId),
			"instanceName": resp.InstanceName,
		},
	})
}
