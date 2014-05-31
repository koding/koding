package kloud

import (
	"errors"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/protocol"
	"strconv"
	"time"

	"github.com/koding/kite"
)

type BuildArgs struct {
	MachineId    string
	ImageName    string
	InstanceName string
	Username     string
}

var (
	defaultImageName = "koding-klient-0.0.1"

	ErrAlreadyInitialized = errors.New("Machine is already initialized and prepared.")
	ErrBuilding           = errors.New("Machine is being build. Hold on...")
)

func (k *Kloud) build(r *kite.Request) (interface{}, error) {
	// this locks are important to prevent consecutive calls from the same user
	k.idlock.Get(r.Username).Lock()
	defer k.idlock.Get(r.Username).Unlock()

	args := &BuildArgs{}
	if err := r.Args.One().Unmarshal(args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, errors.New("machineId is missing.")
	}

	state, err := k.Storage.GetState(args.MachineId)
	if err != nil {
		return nil, err
	}

	if state == Building {
		return nil, ErrBuilding
	}

	// if it's something else (stopped, runnning, terminated, ...) it's been
	// already built
	if state != NotInitialized {
		return nil, ErrAlreadyInitialized
	}

	k.Storage.UpdateState(args.MachineId, Building)

	eventId, eventer := k.NewEventer()

	go func() {
		k.idlock.Get(r.Username).Lock()
		defer k.idlock.Get(r.Username).Unlock()

		args.Username = r.Username
		err := k.buildMachine(args, eventer)
		if err != nil {
			k.Log.Error("Building machine failed. Machine is marked as UNKNOWN.\n"+
				"Any other call are now forbidden until the state is resolved manually.\n"+
				"Args: %v User: %s EventId: %d Events: %s",
				args, r.Username, eventId, eventer)

			k.Storage.UpdateState(args.MachineId, NotInitialized)
		} else {
			k.Storage.UpdateState(args.MachineId, Running)
		}
	}()

	return eventId, nil
}

func (k *Kloud) buildMachine(args *BuildArgs, ev eventer.Eventer) error {
	imageName := defaultImageName
	if args.ImageName != "" {
		imageName = args.ImageName
	}

	signFunc := func() (string, string, error) {
		return createKey(args.Username, k.KontrolURL, k.KontrolPrivateKey, k.KontrolPublicKey)
	}

	instanceName := args.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	if args.InstanceName != "" {
		instanceName = args.InstanceName
	}

	provider, err := k.provider(args.MachineId)
	if err != nil {
		return err
	}

	buildOptions := &protocol.BuildOptions{
		ImageName:    imageName,
		InstanceName: instanceName,
		SignFunc:     signFunc,
		Eventer:      ev,
	}

	buildResponse, err := provider.Build(buildOptions)
	if err != nil {
		return err
	}

	return k.Storage.Update(args.MachineId, buildResponse)
}
