package stack

import (
	"errors"
	"fmt"
	"strings"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/machinestate"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

// InfoResponse is returned from a info method
type InfoResponse struct {
	// State defines the state of the machine
	State machinestate.State `json:"state"`

	// Name defines the name of the machine.
	Name string `json:"name,omitempty"`

	// InstanceType defines the type of the given machine
	InstanceType string `json:"instanceType,omitempty"`
}

func (k *Kloud) Info(r *kite.Request) (interface{}, error) {
	machine, err := k.GetMachine(r)
	if err != nil {
		return nil, err
	}

	stater, ok := machine.(Stater)
	if !ok {
		return nil, NewError(ErrStaterNotImplemented)
	}

	if stater.State() == machinestate.NotInitialized {
		return &InfoResponse{
			State: machinestate.NotInitialized,
			Name:  "not-initialized-instance",
		}, nil
	}

	i, ok := machine.(Infoer)
	if !ok {
		return nil, fmt.Errorf("Provider doesn't implement %s interface", r.Method)
	}

	ctx := request.NewContext(context.Background(), r)
	response, err := i.Info(ctx)
	if err != nil {
		return nil, err
	}

	if response.State == machinestate.Unknown {
		response.State = stater.State()
	}

	return response, nil
}

func (k *Kloud) Build(r *kite.Request) (interface{}, error) {
	buildFunc := func(ctx context.Context, machine interface{}) error {
		builder, ok := machine.(Builder)
		if !ok {
			return fmt.Errorf("Provider doesn't implement %s interface", r.Method)
		}

		return builder.Build(ctx)
	}

	return k.coreMethods(r, buildFunc)
}

func (k *Kloud) Destroy(r *kite.Request) (resp interface{}, reqErr error) {
	destroyFunc := func(ctx context.Context, machine interface{}) error {
		destroyer, ok := machine.(Destroyer)
		if !ok {
			return fmt.Errorf("Provider doesn't implement %s interface", r.Method)
		}

		return destroyer.Destroy(ctx)
	}

	return k.coreMethods(r, destroyFunc)
}

func (k *Kloud) Start(r *kite.Request) (resp interface{}, reqErr error) {
	startFunc := func(ctx context.Context, machine interface{}) error {
		starter, ok := machine.(Starter)
		if !ok {
			return fmt.Errorf("Provider doesn't implement %s interface", r.Method)
		}

		err := starter.Start(ctx)
		if err != nil {
			// special case `NetworkOut` error since client relies on this
			// to show a modal
			if strings.Contains(err.Error(), "NetworkOut") {
				err = NewEventerError(err)
			}

			// special case `plan is expired` error since client relies on this to
			// show a modal
			if strings.Contains(strings.ToLower(err.Error()), "plan is expired") {
				err = NewEventerError(err)
			}
		}

		return err
	}

	return k.coreMethods(r, startFunc)
}

func (k *Kloud) Stop(r *kite.Request) (resp interface{}, reqErr error) {
	stopFunc := func(ctx context.Context, machine interface{}) error {
		stopper, ok := machine.(Stopper)
		if !ok {
			return fmt.Errorf("Provider doesn't implement %s interface", r.Method)
		}

		return stopper.Stop(ctx)
	}

	return k.coreMethods(r, stopFunc)
}

func (k *Kloud) Reinit(r *kite.Request) (resp interface{}, reqErr error) {
	reinitFunc := func(ctx context.Context, machine interface{}) error {
		reiniter, ok := machine.(Reiniter)
		if !ok {
			return fmt.Errorf("Provider doesn't implement %s interface", r.Method)
		}

		return reiniter.Reinit(ctx)
	}

	return k.coreMethods(r, reinitFunc)
}

func (k *Kloud) Resize(r *kite.Request) (resp interface{}, reqErr error) {
	resizeFunc := func(ctx context.Context, machine interface{}) error {
		resizer, ok := machine.(Resizer)
		if !ok {
			return fmt.Errorf("Provider doesn't implement %s interface", r.Method)
		}

		return resizer.Resize(ctx)
	}

	return k.coreMethods(r, resizeFunc)
}

func (k *Kloud) Restart(r *kite.Request) (resp interface{}, reqErr error) {
	restartFunc := func(ctx context.Context, machine interface{}) error {
		restart, ok := machine.(Restarter)
		if !ok {
			return fmt.Errorf("Provider doesn't implement %s interface", r.Method)
		}

		return restart.Restart(ctx)
	}

	return k.coreMethods(r, restartFunc)
}

func (k *Kloud) CreateSnapshot(r *kite.Request) (reqResp interface{}, reqErr error) {
	snapshotFunc := func(ctx context.Context, machine interface{}) error {
		s, ok := machine.(Snapshotter)
		if !ok {
			return fmt.Errorf("Provider doesn't implement %s interface", r.Method)
		}

		return s.CreateSnapshot(ctx)
	}

	return k.coreMethods(r, snapshotFunc)
}

func (k *Kloud) DeleteSnapshot(r *kite.Request) (resp interface{}, kiteErr error) {
	var args struct {
		SnapshotId string
	}

	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.SnapshotId == "" {
		return nil, NewError(ErrSnapshotIdMissing)
	}

	defer func() {
		if kiteErr != nil {
			k.Log.New("username", r.Username, "snapshotId", args.SnapshotId).Error("Could not delete snapshot: %s", kiteErr.Error())
		}
	}()

	account, err := modelhelper.GetAccount(r.Username)
	if err != nil {
		return nil, err
	}

	snapshot, err := modelhelper.GetSnapshot(args.SnapshotId)
	if err != nil {
		return nil, err
	}

	if account.Id != snapshot.OriginId {
		return nil, fmt.Errorf("User '%s' is not authenticated to remove the snapshot", r.Username)
	}

	ctx := k.ContextCreator(context.Background())
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	svc, err := sess.AWSClients.Region(snapshot.Region)
	if err != nil {
		return nil, err
	}

	if err := svc.DeleteSnapshot(args.SnapshotId); err != nil {
		return nil, err
	}

	if err := modelhelper.DeleteSnapshot(args.SnapshotId); err != nil {
		return nil, err
	}

	return true, nil
}
