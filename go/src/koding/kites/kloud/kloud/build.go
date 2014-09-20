package kloud

import (
	"fmt"
	"strconv"
	"strings"
	"time"

	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"

	"github.com/koding/kite"
)

func (k *Kloud) Build(r *kite.Request) (buildResp interface{}, buildErr error) {
	machine, err := k.PrepareMachine(r)
	if err != nil {
		return nil, err
	}

	defer func() {
		if buildErr != nil {
			k.Locker.Unlock(machine.Id)
		}
	}()

	if machine.State == machinestate.Building {
		return nil, NewError(ErrMachineIsBuilding)
	}

	if machine.State == machinestate.Unknown {
		return nil, NewError(ErrMachineUnknownState)
	}

	// if it's something else (stopped, runnning, ...) it's been already built
	if !machine.State.In(machinestate.Terminated, machinestate.NotInitialized) {
		return nil, NewError(ErrMachineInitialized)
	}

	k.Storage.UpdateState(machine.Id, machinestate.Building)
	machine.Eventer = k.NewEventer(r.Method + "-" + machine.Id)

	// prepare instance name
	instanceName := "user-" + r.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	i, ok := machine.Builder["instanceName"]
	if !ok || i == "" {
		// if it's empty we use the instance name that was generated above
		machine.Builder["instanceName"] = instanceName
	} else {
		instanceName, ok = i.(string)
		if !ok {
			return nil, fmt.Errorf("instanceName is malformed: %v", i)
		}
	}

	// start our build process in async way
	go k.build(r, machine)

	// but let the user know thay they can track us via the given event id
	return ControlResult{
		EventId: machine.Eventer.Id(),
		State:   machinestate.Building,
	}, nil

}

func (k *Kloud) build(r *kite.Request, m *protocol.Machine) (resp interface{}, err error) {
	k.idlock.Get(m.Id).Lock()
	defer k.idlock.Get(m.Id).Unlock()

	// This is executed as the final step which stops the eventer and updates
	// the state in the storage.
	defer func() {
		status := machinestate.Running
		msg := "Build is finished successfully."
		eventErr := ""

		if err != nil {
			k.Log.Error("[%s] building failed. err %s.", m.Id, err.Error())

			status = m.State
			msg = ""
			eventErr = fmt.Sprintf("Building failed. Please contact support.")
		}

		// update final status in storage
		k.Storage.UpdateState(m.Id, status)

		// unlock distributed lock
		k.Locker.Unlock(m.Id)

		// let them know we are finished with our work
		m.Eventer.Push(&eventer.Event{
			Message:    msg,
			Status:     status,
			Percentage: 100,
			Error:      eventErr,
		})
	}()

	msg := fmt.Sprintf("Building process started. Provider '%s'. MachineId: %+v",
		m.Provider, m.Id)

	m.Eventer.Push(&eventer.Event{Message: msg, Status: machinestate.Building})

	buildStub := `
provider      : %s
machineId     : %s
username      : %s
instanceName  : %s
`

	buildInfo := fmt.Sprintf(buildStub,
		m.Provider,
		m.Id,
		r.Username,
		m.Builder["instanceName"].(string),
	)

	k.Log.Info("[%s] building machine with following data: %s", m.Id, buildInfo)

	var artifact *protocol.Artifact

	provider, ok := k.providers[m.Provider]
	if !ok {
		return nil, NewError(ErrProviderAvailable)
	}

	builder, ok := provider.(protocol.Builder)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	artifact, err = builder.Build(m)
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
	m.Builder["instanceName"] = artifact.InstanceName

	// k.Log.Debug("[controller]: building machine finished, result artifact is: %# v",
	// 	pretty.Formatter(artifact))

	resultStub := `
username   : %s
domain     : %s
ip address : %s
instance   : %s
kite query : %s
`

	resultInfo := fmt.Sprintf(resultStub,
		artifact.Username,
		artifact.DomainName,
		artifact.IpAddress,
		artifact.InstanceName,
		artifact.KiteQuery,
	)

	k.Log.Info("[%s] building machine was successfull. Artifact data: %s",
		m.Id, resultInfo)

	storageData := map[string]interface{}{
		"ipAddress":    artifact.IpAddress,
		"domainName":   artifact.DomainName,
		"instanceId":   artifact.InstanceId,
		"instanceName": artifact.InstanceName,
		"queryString":  artifact.KiteQuery,
	}

	k.Log.Info("[%s] ========== %s finished ==========", m.Id, strings.ToUpper(r.Method))

	return true, k.Storage.Update(m.Id, &StorageData{
		Type: "build",
		Data: storageData,
	})
}
