package kloud

import (
	"fmt"
	"strconv"
	"time"

	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"
	"github.com/kr/pretty"

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

	instanceName := r.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	i, ok := c.Machine.Data["instanceName"]
	if !ok || i == "" {
		// if it's empty we use the instance name that was generated above
		c.Machine.Data["instanceName"] = instanceName
	} else {
		instanceName, ok = i.(string)
		if !ok {
			return nil, fmt.Errorf("instanceName is malformed: %v", i)
		}
	}

	go func() {
		k.idlock.Get(c.MachineId).Lock()
		defer k.idlock.Get(c.MachineId).Unlock()

		status := machinestate.Running
		msg := "Build is finished successfully."

		err := k.buildMachine(r.Username, c)
		if err != nil {
			k.Log.Error("[controller] building machine for id '%s' failed: %s.", c.MachineId, err.Error())

			status = c.CurrenState
			msg = err.Error()
		} else {
			k.Log.Info("[controller] building machine for id '%s' is successfull. Instance name: %s",
				c.MachineId, instanceName)
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
	machOptions := &protocol.MachineOptions{
		MachineId:  c.MachineId,
		Eventer:    c.Eventer,
		Credential: c.Machine.Credential,
		Builder:    c.Machine.Data,
		Deploy:     k.Deploy,
	}

	msg := fmt.Sprintf("Building process started. Provider '%s'. Build options: %+v",
		c.ProviderName, machOptions)

	c.Eventer.Push(&eventer.Event{Message: msg, Status: machinestate.Building})

	buildStub := `
provider      : %s
machineId     : %s
username      : %s
instanceName  : %s
meta data     : %# v
`

	buildInfo := fmt.Sprintf(buildStub,
		c.ProviderName,
		c.MachineId,
		username,
		c.Machine.Data["instanceName"].(string),
		pretty.Formatter(c.Machine.Data),
	)

	k.Log.Info("[controller] building machine with following data: %s", buildInfo)

	artifact, err := c.Builder.Build(machOptions)
	if err != nil {
		return err
	}
	if artifact == nil {
		return NewError(ErrBadResponse)
	}
	k.Log.Debug("[controller]: building machine finished, result artifact is: %# v", pretty.Formatter(artifact))

	storageData := map[string]interface{}{
		"ipAddress":    artifact.IpAddress,
		"instanceId":   artifact.InstanceId,
		"instanceName": artifact.InstanceName,
	}

	// if the username is not explicit changed, assign the original username to it
	if artifact.Username == "" {
		artifact.Username = username
	}

	// TODO: I don't feel good about this, fix it
	if k.Deployer != nil && artifact.SSHPrivateKey != "" {
		deployArtifact, err := k.Deployer.Deploy(artifact)
		if err != nil {
			return err
		}

		storageData["queryString"] = deployArtifact.KiteQuery
	}

	cleaner, ok := k.providers[c.ProviderName].(protocol.Cleaner)
	if ok {
		if err := cleaner.Cleanup(artifact); err != nil {
			return err
		}
	}

	return k.Storage.Update(c.MachineId, &StorageData{
		Type: "build",
		Data: storageData,
	})
}
