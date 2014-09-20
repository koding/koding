package kloud

import (
	"fmt"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/protocol"
	"strconv"
	"time"

	"github.com/koding/kite"
)

func (k *Kloud) Build(r *kite.Request) (resp interface{}, reqErr error) {
	buildFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
		// alrady building bro ...
		if m.State == machinestate.Building {
			return nil, NewError(ErrMachineIsBuilding)
		}

		// what? should never happen!
		if m.State == machinestate.Unknown {
			return nil, NewError(ErrMachineUnknownState)
		}

		// if it's something else (stopped, runnning, ...) it's been already built
		if !m.State.In(machinestate.Terminated, machinestate.NotInitialized) {
			return nil, NewError(ErrMachineInitialized)
		}

		// prepare instance name
		instanceName := "user-" + m.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
		i, ok := m.Builder["instanceName"]
		if !ok || i == "" {
			// if it's empty we use the instance name that was generated above
			m.Builder["instanceName"] = instanceName
		} else {
			instanceName, ok = i.(string)
			if !ok {
				return nil, fmt.Errorf("instanceName is malformed: %v", i)
			}
		}

		artifact, err := p.Build(m)
		if err != nil {
			return nil, err
		}

		if artifact == nil {
			return nil, NewError(ErrBadResponse)
		}

		// if the username is not explicit changed, assign the original username to it
		if artifact.Username == "" {
			artifact.Username = m.Username
		}

		resultStub := `
username   : %s
domain     : %s
ip address : %s
instance   : %s
kite query : %s
`
		resultInfo := fmt.Sprintf(resultStub, artifact.Username, artifact.DomainName,
			artifact.IpAddress, artifact.InstanceName, artifact.KiteQuery)
		k.Log.Info("[%s] building machine was successfull. Artifact data: %s",
			m.Id, resultInfo)

		return k.Storage.Update(m.Id, &StorageData{
			Type: "build",
			Data: map[string]interface{}{
				"ipAddress":    artifact.IpAddress,
				"domainName":   artifact.DomainName,
				"instanceId":   artifact.InstanceId,
				"instanceName": artifact.InstanceName,
				"queryString":  artifact.KiteQuery,
			},
		}), nil
	}

	return k.coreMethods(r, buildFunc)
}
