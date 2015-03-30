package kloud

import (
	"fmt"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"strings"
	"time"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

type ControlResult struct {
	EventId string `json:"eventId"`
}

type machineFunc func(context.Context, interface{}) error

// statePair defines a methods start and final states
type statePair struct {
	start machinestate.State
	final machinestate.State
}

var states = map[string]*statePair{
	"build":          &statePair{start: machinestate.Building, final: machinestate.Running},
	"start":          &statePair{start: machinestate.Starting, final: machinestate.Running},
	"stop":           &statePair{start: machinestate.Stopping, final: machinestate.Stopped},
	"destroy":        &statePair{start: machinestate.Terminating, final: machinestate.Terminated},
	"restart":        &statePair{start: machinestate.Rebooting, final: machinestate.Running},
	"resize":         &statePair{start: machinestate.Pending, final: machinestate.Running},
	"reinit":         &statePair{start: machinestate.Terminating, final: machinestate.Running},
	"createSnapshot": &statePair{start: machinestate.Snapshotting, final: machinestate.Running},
	"deleteSnapshot": &statePair{start: machinestate.Snapshotting, final: machinestate.Running},
}

// coreMethods is running and returning the response for the given machineFunc.
// This method is used to avoid duplicate codes in many codes (because we do
// the same steps for each of them).
func (k *Kloud) coreMethods(r *kite.Request, fn machineFunc) (result interface{}, reqErr error) {
	// calls with zero arguments causes args to be nil. Check it that we
	// don't get a beloved panic
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args struct {
		MachineId string
		Provider  string
	}

	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, NewError(ErrMachineIdMissing)
	}

	if args.Provider == "" {
		return nil, NewError(ErrProviderIsMissing)
	}

	k.track(args.Provider, args.MachineId, r.Method)

	// Lock the machine id so no one else can access it. It means this
	// kloud instance is now responsible for this machine id. Its basically
	// a distributed lock. It's unlocked when there is an error or if the
	// method call is finished (unlocking is done inside the responsible
	// method calls).
	if r.Method != "info" {
		if err := k.Locker.Lock(args.MachineId); err != nil {
			return nil, err
		}

		// if something goes wrong after step reset the document which is was
		// set in the by previous step by Locker.Lock(). If there is no error,
		// the lock will be unlocked in the respective method  function.
		defer func() {
			if reqErr != nil {
				// otherwise that means Locker.Lock or something else in
				// ControlFunc failed. Reset the lock again so it can be acquired by
				// others.
				k.Locker.Unlock(args.MachineId)
			}
		}()
	}

	k.Log.Debug("args %+v", args)

	provider, ok := k.providers[args.Provider]
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	p, ok := provider.(Provider)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	ctx := request.NewContext(context.Background(), r)
	// add publicKeys to be deployed to the machine, the machine provider is
	// responsible of deploying it to the machine while building it.
	ctx = publickeys.NewContext(ctx, k.PublicKeys)

	if k.ContextCreator != nil {
		ctx = k.ContextCreator(ctx)
	}

	// each method has his own unique eventer
	eventId := r.Method + "-" + args.MachineId
	ev := k.NewEventer(eventId)
	ctx = eventer.NewContext(ctx, ev)

	machine, err := p.Machine(ctx, args.MachineId)
	if err != nil {
		return nil, err
	}

	stater, ok := machine.(Stater)
	if !ok {
		return nil, NewError(ErrStaterNotImplemented)
	}
	currentState := stater.State()

	// Check if the given method is in valid methods of that current state. For
	// example if the method is "build", and the state is "stopped" than this
	// will return an error.
	if !methodIn(r.Method, stater.State().ValidMethods()...) {
		return nil, fmt.Errorf("%s not allowed for current state '%s'. Allowed methods are: %v",
			r.Method, strings.ToLower(stater.State().String()), stater.State().ValidMethods())
	}

	pair, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}

	ev.Push(&eventer.Event{
		Message: r.Method + " started",
		Status:  pair.start,
	})

	// Start our core method in a goroutine to not block it for the client
	// side. However we do return an event id which is an unique for tracking
	// the current status of the running method.
	go func() {
		finalEvent := &eventer.Event{
			Message:    r.Method + " finished",
			Status:     pair.final,
			Percentage: 100,
		}

		k.Log.Info("[%s] ======> %s started <======", args.Provider, args.MachineId, strings.ToUpper(r.Method))
		start := time.Now()

		err := fn(ctx, machine)
		if err != nil {
			k.Log.Error("[%s][%s] %s error: %s", args.Provider, args.MachineId, r.Method, err)
			finalEvent.Error = strings.ToTitle(r.Method) + " failed. Please contact support."
			finalEvent.Status = currentState // fallback to to old state
		}

		k.Log.Info("[%s] ======> %s finished (time: %s) <======",
			args.MachineId, strings.ToUpper(r.Method), time.Since(start))

		ev.Push(finalEvent)
		k.Locker.Unlock(args.MachineId)
	}()

	return ControlResult{
		EventId: eventId,
	}, nil
}

func (k *Kloud) GetMachine(r *kite.Request) (resp interface{}, reqErr error) {
	// calls with zero arguments causes args to be nil. Check it that we
	// don't get a beloved panic
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args struct {
		MachineId string
		Provider  string
	}

	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.MachineId == "" {
		return nil, NewError(ErrMachineIdMissing)
	}

	// Lock the machine id so no one else can access it. It means this
	// kloud instance is now responsible for this machine id. Its basically
	// a distributed lock. It's unlocked when there is an error or if the
	// method call is finished (unlocking is done inside the responsible
	// method calls).
	if r.Method != "info" {
		if err := k.Locker.Lock(args.MachineId); err != nil {
			return nil, err
		}

		// if something goes wrong after step reset the document which is was
		// set in the by previous step by Locker.Lock(). If there is no error,
		// the lock will be unlocked in the respective method  function.
		defer func() {
			if reqErr != nil {
				// otherwise that means Locker.Lock or something else in
				// ControlFunc failed. Reset the lock again so it can be acquired by
				// others.
				k.Locker.Unlock(args.MachineId)
			}
		}()
	}

	provider, ok := k.providers[args.Provider]
	if !ok {
		return nil, NewError(ErrProviderAvailable)
	}

	p, ok := provider.(Provider)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	ctx := request.NewContext(context.Background(), r)

	return p.Machine(ctx, args.MachineId)
}

// methodIn checks if the method exist in the given methods
func methodIn(method string, methods ...string) bool {
	for _, m := range methods {
		if method == m {
			return true
		}
	}
	return false
}
