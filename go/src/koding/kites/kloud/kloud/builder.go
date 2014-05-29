package kloud

import (
	"errors"
	"strconv"
	"time"

	"github.com/koding/kite"
)

// Builder is used to create and provisiong a single image or machine for a
// given Provider.
type Builder interface {
	// Prepare is responsible of configuring the builder and validating the
	// given configuration prior Build.
	Prepare(...interface{}) error

	// Build is creating a image and a machine.
	Build(...interface{}) (map[string]interface{}, error)
}

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

	machineData, err := k.Storage.MachineData(args.MachineId)
	if err != nil {
		return nil, err
	}

	p, ok := providers[machineData.Provider]
	if !ok {
		return nil, errors.New("provider not supported")
	}

	provider, ok := p.(Builder)
	if !ok {
		return nil, errors.New("provider doesn't satisfy the builder interface.")
	}

	if err := provider.Prepare(machineData.Credential, machineData.Builders); err != nil {
		return nil, err
	}

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

	artifact, err := provider.Build(snapshotName, machineName, signFunc)
	if err != nil {
		return nil, err
	}

	if err := k.Storage.Update(args.MachineId, artifact); err != nil {
		return nil, err
	}
	return artifact, nil
}
