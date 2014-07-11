package kloud

import (
	"fmt"
	"strconv"
	"time"

	"github.com/koding/kloud/eventer"
	"github.com/koding/kloud/machinestate"
	"github.com/koding/kloud/protocol"

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
			k.Log.Error("[controller] building machine failed for user '%s' with machineId '%s': %s.",
				r.Username, c.MachineId, err.Error())

			status = c.CurrenState
			msg = err.Error()
		} else {
			k.Log.Info("[%s] build for '%s' is successfull. State is now: %+v",
				c.ProviderName, c.InstanceName, status)
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
	// create a random instance name if the it's not passed via argument
	if c.InstanceName == "" {
		c.InstanceName = username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	}

	machOptions := &protocol.MachineOptions{
		MachineId:    c.MachineId,
		Username:     username,
		ImageName:    c.ImageName,
		InstanceName: c.InstanceName,
		Eventer:      c.Eventer,
		Credential:   c.MachineData.Credential.Meta,
		Builder:      c.MachineData.Machine.Meta,
		Deploy:       k.Deploy,
	}

	msg := fmt.Sprintf("Building process started. Provider '%s'. Build options: %+v",
		c.ProviderName, machOptions)

	c.Eventer.Push(&eventer.Event{Message: msg, Status: machinestate.Building})

	k.Log.Debug("[controller]: running method 'build' with machine options %v", machOptions)
	providerArtifact, err := c.Builder.Build(machOptions)
	if err != nil {
		return err
	}
	if providerArtifact == nil {
		return NewError(ErrBadResponse)
	}
	k.Log.Debug("[controller]: method 'build' is successfull %#v", providerArtifact)

	storageData := map[string]interface{}{
		"ipAddress":    providerArtifact.IpAddress,
		"instanceId":   providerArtifact.InstanceId,
		"instanceName": providerArtifact.InstanceName,
	}

	if k.Deployer != nil && providerArtifact.SSHPrivateKey != "" {
		deployOpts := &protocol.DeployOptions{
			Artifact: providerArtifact,
			Username: username,
		}

		deployArtifact, err := k.Deployer.Deploy(deployOpts)
		if err != nil {
			return err
		}

		storageData["queryString"] = deployArtifact.KiteQuery
	}

	cleaner, ok := k.providers[c.ProviderName].(protocol.Cleaner)
	if ok {
		if err := cleaner.Clean(providerArtifact); err != nil {
			return err
		}
	}

	return k.Storage.Update(c.MachineId, &StorageData{
		Type: "build",
		Data: storageData,
	})
}
