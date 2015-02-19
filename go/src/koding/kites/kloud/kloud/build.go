package kloud

import (
	"fmt"
	"koding/kites/kloud/protocol"
	"strconv"
	"time"

	"github.com/koding/kite"
)

func (k *Kloud) Build(r *kite.Request) (resp interface{}, reqErr error) {
	buildFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
		if r.Args == nil {
			return nil, NewError(ErrNoArguments)
		}

		var args struct {
			SnapshotId string
		}

		if err := r.Args.One().Unmarshal(&args); err != nil {
			return nil, err
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

		artifact, err := p.Build(args.SnapshotId, m)
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

		resultInfo := fmt.Sprintf("username: [%s], instanceId: [%s], ipAdress: [%s], kiteQuery: [%s]",
			artifact.Username, artifact.InstanceId, artifact.IpAddress, artifact.KiteQuery)

		k.Log.Info("[%s] ========== BUILD results ========== %s",
			m.Id, resultInfo)

		return k.Storage.Update(m.Id, &StorageData{
			Type: "build",
			Data: map[string]interface{}{
				"ipAddress":    artifact.IpAddress,
				"domainName":   artifact.DomainName,
				"instanceId":   artifact.InstanceId,
				"instanceName": artifact.InstanceName,
				"instanceType": artifact.InstanceType,
				"queryString":  artifact.KiteQuery,
				"imageId":      artifact.ImageId,
			},
		}), nil
	}

	return k.coreMethods(r, buildFunc)
}
