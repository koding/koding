package kloud

import (
	"errors"
	"fmt"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud/machinestate"
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

type BuildResult struct {
	EventId string             `json:"eventId"`
	State   machinestate.State `json:"state"`
}

var (
	defaultImageName = "koding-klient-0.0.1"
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

	if state == machinestate.Building {
		return nil, ErrBuilding
	}

	if state == machinestate.Unknown {
		return nil, ErrUnknownState
	}

	// if it's something else (stopped, runnning, terminated, ...) it's been
	// already built
	if state != machinestate.NotInitialized {
		return nil, ErrAlreadyInitialized
	}

	k.Storage.UpdateState(args.MachineId, machinestate.Building)

	eventId, ev := k.NewEventer()

	go func() {
		k.idlock.Get(r.Username).Lock()
		defer k.idlock.Get(r.Username).Unlock()

		status := machinestate.Running
		msg := "Build is finished successfully."

		//lets pass it alongside with args
		args.Username = r.Username

		err := k.buildMachine(args, ev)
		if err != nil {
			k.Log.Error("Building machine failed. Machine state is marked as ERROR.\n"+
				"Any other calls are now forbidden until the state is resolved manually.\n"+
				"Args: %v User: %s EventId: %d Events: %s",
				args, r.Username, eventId, ev)

			status = machinestate.Unknown
			msg = err.Error()
		}

		k.Storage.UpdateState(args.MachineId, status)
		ev.Push(&eventer.Event{Message: msg, Status: status})
	}()

	return BuildResult{
		EventId: eventId,
		State:   machinestate.Building,
	}, nil
}

func (k *Kloud) buildMachine(args *BuildArgs, ev eventer.Eventer) error {
	imageName := defaultImageName
	if args.ImageName != "" {
		imageName = args.ImageName
	}

	instanceName := args.Username + "-" + strconv.FormatInt(time.Now().UTC().UnixNano(), 10)
	if args.InstanceName != "" {
		instanceName = args.InstanceName
	}

	m, err := k.Storage.Get(args.MachineId, &GetOption{
		IncludeMachine:    true,
		IncludeCredential: true,
	})
	if err != nil {
		return err
	}

	provider, ok := providers[m.Provider]
	if !ok {
		return errors.New("provider not supported")
	}

	if err := provider.Prepare(m.Credential.Meta, m.Machine.Meta); err != nil {
		return err
	}

	buildOptions := &protocol.BuildOptions{
		MachineId:    args.MachineId,
		Username:     args.Username,
		ImageName:    imageName,
		InstanceName: instanceName,
		Eventer:      ev,
	}

	msg := fmt.Sprintf("Building process started. Provider '%s'. Build options: %+v",
		provider.Name(), buildOptions)
	k.Log.Info(msg)

	ev.Push(&eventer.Event{Message: msg, Status: machinestate.Building})
	buildResponse, err := provider.Build(buildOptions)
	if err != nil {
		return err
	}

	return k.Storage.Update(args.MachineId, buildResponse)
}
