package kloud

import (
	"errors"
	"strconv"
	"time"

	"github.com/koding/kite"
)

type BuildResponse struct {
	MachineName string `json:"machineName" mapstructure:"machineName"`
	MachineId   int    `json:"machineId" mapstructure:"machineId"`
	KiteId      string `json:"kiteId" mapstructure:"kiteId"`
	IpAddress   string `json:"ipAddress" mapstructure:"ipAddress"`
}

type BuildArgs struct {
	MachineId    string
	SnapshotName string
	MachineName  string
}

func (k *Kloud) build(r *kite.Request) (interface{}, error) {
	args := &BuildArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, errors.New("machineId is missing.")
	}

	// this locks are important to prevent consecutive calls from the same user
	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	snapshotName := defaultSnapshotName
	if args.SnapshotName != "" {
		snapshotName = args.SnapshotName
	}

	signFunc := func() (string, string, error) {
		return createKey(r.Username, k.KontrolURL, k.KontrolPrivateKey, k.KontrolPublicKey)
	}

	machineName := r.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	if args.MachineName != "" {
		machineName = args.MachineName
	}

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return nil, err
	}

	artifact, err := provider.Build(snapshotName, machineName, signFunc)
	if err != nil {
		return nil, err
	}

	if err := k.Storage.Update(args.MachineId, artifact); err != nil {
		return nil, err
	}

	return artifact, nil
}
