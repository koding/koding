package stack

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

// TraceKey is key for storing TraceID string in context.Context.
// When a kite's request contains debug field (in the payload) set to
// true, kloud generates unique TraceID, enables debug logging for
// whole codepath, and sends the TraceID to other microservices
// if needed (e.g. terraformer).
var TraceKey struct {
	byte `key:"traceKey"`
}

func TraceFromContext(ctx context.Context) (string, bool) {
	traceID, ok := ctx.Value(TraceKey).(string)

	if !ok || traceID == "" {
		return "", false
	}

	return traceID, true
}

type ControlResult struct {
	EventId string `json:"eventId"`
}

type machineFunc func(context.Context, Machiner) error

// statePair defines a methods start and final states
type statePair struct {
	start machinestate.State
	final machinestate.State
}

var states = map[string]*statePair{
	"build":          {start: machinestate.Building, final: machinestate.Running},
	"reinit":         {start: machinestate.Building, final: machinestate.Running},
	"start":          {start: machinestate.Starting, final: machinestate.Running},
	"stop":           {start: machinestate.Stopping, final: machinestate.Stopped},
	"destroy":        {start: machinestate.Terminating, final: machinestate.Terminated},
	"restart":        {start: machinestate.Rebooting, final: machinestate.Running},
	"resize":         {start: machinestate.Pending, final: machinestate.Running},
	"createSnapshot": {start: machinestate.Snapshotting, final: machinestate.Running},
	"deleteSnapshot": {start: machinestate.Snapshotting, final: machinestate.Running},
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

	k.Log.Debug("solo: calling %q by %q with %q", r.Username, r.Method, r.Args.Raw)

	var args struct {
		MachineId string
		Provider  string
		Debug     bool
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
		return nil, NewError(ErrProviderNotFound)
	}

	p, ok := provider.(Provider)
	if !ok {
		return nil, NewError(ErrProviderNotImplemented)
	}

	ctx := request.NewContext(context.Background(), r)
	// add publicKeys to be deployed to the machine, the machine provider is
	// responsible of deploying it to the machine while building it.
	if k.PublicKeys != nil {
		ctx = publickeys.NewContext(ctx, k.PublicKeys)
	}

	if k.ContextCreator != nil {
		ctx = k.ContextCreator(ctx)
	}

	// if debug is enabled, generate TraceID and pass it with the context
	if args.Debug {
		ctx = k.setTraceID(r.Username, r.Method, ctx)
	}

	// old events are not needed anymore, so we're just going to remove them.
	k.cleanupEventers(args.MachineId)

	// each method has his own unique eventer
	eventId := r.Method + "-" + args.MachineId
	ev := k.NewEventer(eventId)
	ctx = eventer.NewContext(ctx, ev)

	machine, err := p.Machine(ctx, args.MachineId)
	if err != nil {
		return nil, err
	}

	m, ok := machine.(Machiner)
	if !ok {
		return nil, NewError(ErrMachineNotImplemented)
	}

	if m.ProviderName() != args.Provider {
		k.Log.Debug("want provider %q, got %q", m.ProviderName(), args.Provider)

		return nil, NewError(ErrProviderIsWrong)
	}

	// Check if the given method is in valid methods of that current state. For
	// example if the method is "build", and the state is "stopped" than this
	// will return an error.
	if !methodIn(r.Method, m.State().ValidMethods()...) {
		return nil, fmt.Errorf("%s not allowed for current state '%s'. Allowed methods are: %v",
			r.Method, strings.ToLower(m.State().String()), m.State().ValidMethods())
	}

	pair, ok := states[r.Method]
	if !ok {
		return nil, fmt.Errorf("no state pair available for %s", r.Method)
	}

	tags := []string{
		"instanceId:" + args.MachineId,
		"provider:" + args.Provider,
	}

	ctx = k.traceRequest(ctx, tags)

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

		k.Log.Info("[%s] ======> %s started (requester: %s, provider: %s)<======",
			args.MachineId, strings.ToUpper(r.Method), r.Username, args.Provider)
		start := time.Now()
		err := fn(ctx, m)
		if err != nil {
			// don't pass the error directly to the eventer, mask it to avoid
			// error leaking to the client. We just log it here.
			k.Log.Error("[%s] ======> %s finished with error: '%s' (requester: %s, provider: %s) <======",
				args.MachineId, strings.ToUpper(r.Method), err, r.Username, args.Provider)

			finalEvent.Error = strings.ToTitle(r.Method) + " failed. Please contact support."

			// however, eventerErr is an error we want to pass explicitly to
			// the client side
			if eventerErr, ok := err.(*EventerError); ok {
				finalEvent.Error = eventerErr.Error()
			}

			finalEvent.Status = m.State() // fallback to to old state
		} else {
			k.Log.Info("[%s] ======> %s finished (time: %s, requester: %s, provider: %s) <======",
				args.MachineId, strings.ToUpper(r.Method), time.Since(start), r.Username, args.Provider)
		}

		ev.Push(finalEvent)
		k.Locker.Unlock(args.MachineId)
		k.send(ctx)
	}()

	return &ControlResult{
		EventId: eventId,
	}, nil
}

func (k *Kloud) GetMachine(r *kite.Request) (machine Machiner, reqErr error) {
	// calls with zero arguments causes args to be nil. Check it that we
	// don't get a beloved panic
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args struct {
		MachineId string
		Provider  string
		Debug     bool
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

	if args.Provider == "" {
		return nil, NewError(ErrProviderIsMissing)
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

	if args.Debug {
		ctx = k.setTraceID(r.Username, r.Method, ctx)
	}

	v, err := p.Machine(ctx, args.MachineId)
	if err != nil {
		return nil, err
	}

	m, ok := v.(Machiner)
	if !ok {
		return nil, NewError(ErrMachineNotImplemented)
	}

	return m, nil
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

// cleanupEventers cleans all other eventers for the given id
func (k *Kloud) cleanupEventers(id string) {
	for method := range states {
		eventId := method + "-" + id
		delete(k.Eventers, eventId)
	}
}
