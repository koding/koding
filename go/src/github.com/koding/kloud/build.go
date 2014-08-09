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

type Build struct {
	*Kloud
	deployer kite.Handler
}

// prepare prepares the steps to initialize the build. The build is done
// async, therefore if there is anything that needs to be checked it needs to
// be done. Any error here is passed directly to the client.
func (b *Build) prepare(r *kite.Request, c *Controller) (interface{}, error) {
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

	b.Storage.UpdateState(c.MachineId, machinestate.Building)
	c.Eventer = b.NewEventer(r.Method + "-" + c.MachineId)

	instanceName := r.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	i, ok := c.Machine.Builder["instanceName"]
	if !ok || i == "" {
		// if it's empty we use the instance name that was generated above
		c.Machine.Builder["instanceName"] = instanceName
	} else {
		instanceName, ok = i.(string)
		if !ok {
			return nil, fmt.Errorf("instanceName is malformed: %v", i)
		}
	}

	// start our build process in async way
	go b.start(r, c)

	return ControlResult{
		EventId: c.Eventer.Id(),
		State:   machinestate.Building,
	}, nil
}

func (b *Build) start(r *kite.Request, c *Controller) (resp interface{}, err error) {
	b.idlock.Get(c.MachineId).Lock()
	defer b.idlock.Get(c.MachineId).Unlock()

	defer func() {
		status := machinestate.Running
		msg := "Build is finished successfully."

		if err != nil {
			b.Log.Error("[controller] building machine for id '%s' failed: %s.", c.MachineId, err.Error())
			status = c.CurrenState
			msg = err.Error()
		} else {
			b.Log.Info("[controller] building machine for id '%s' is successfull. Instance name: %s",
				c.MachineId, c.Machine.Builder["instanceName"].(string))
		}

		b.Storage.UpdateState(c.MachineId, status)
		b.Storage.ResetAssignee(c.MachineId)
		c.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
		})
	}()

	machOptions := &protocol.Machine{
		MachineId:  c.MachineId,
		Eventer:    c.Eventer,
		Credential: c.Machine.Credential,
		Builder:    c.Machine.Builder,
	}

	msg := fmt.Sprintf("Building process started. Provider '%s'. MachineId: %+v",
		c.ProviderName, c.MachineId)

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
		r.Username,
		c.Machine.Builder["instanceName"].(string),
		pretty.Formatter(c.Machine.Builder),
	)

	b.Log.Info("[controller] building machine with following data: %s", buildInfo)
	artifact, err := c.Builder.Build(machOptions)
	if err != nil {
		return nil, err
	}
	if artifact == nil {
		return nil, NewError(ErrBadResponse)
	}

	// if the username is not explicit changed, assign the original username to it
	if artifact.Username == "" {
		artifact.Username = r.Username
	}

	// update if we somehow updated in build process
	c.Machine.Builder["instanceName"] = artifact.InstanceName

	r.Context.Set("buildArtifact", artifact)

	deployArtifact, err := b.deployer.ServeKite(r)
	if err != nil {
		return nil, err
	}

	// garbage collect it
	r.Context = nil

	b.Log.Debug("[controller]: building machine finished, result artifact is: %# v",
		pretty.Formatter(artifact))

	storageData := map[string]interface{}{
		"ipAddress":    artifact.IpAddress,
		"instanceId":   artifact.InstanceId,
		"instanceName": artifact.InstanceName,
	}

	storageData["queryString"] = deployArtifact.(*protocol.Artifact).KiteQuery

	return true, b.Storage.Update(c.MachineId, &StorageData{
		Type: "build",
		Data: storageData,
	})
}
