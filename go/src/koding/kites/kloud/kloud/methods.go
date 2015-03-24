package kloud

import (
	"fmt"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

func (k *Kloud) Build(r *kite.Request) (interface{}, error) {
	buildFunc := func(ctx context.Context, machine interface{}) error {
		ev, ok := eventer.FromContext(ctx)
		if !ok {
			return fmt.Errorf("eventer context is not available")
		}

		ev.Push(&eventer.Event{
			Message: "Building started",
			Status:  machinestate.Building,
		})

		builder, ok := machine.(Builder)
		if !ok {
			return NewError(ErrBuilderNotImplemented)
		}

		stater, ok := machine.(Stater)
		if !ok {
			return NewError(ErrStaterNotImplemented)
		}
		currentState := stater.State()

		finalEvent := &eventer.Event{
			Message:    "Building finished",
			Status:     machinestate.Running,
			Percentage: 100,
		}

		err := builder.Build(ctx)
		if err != nil {
			finalEvent.Error = "Build failed. Please contact support."
			finalEvent.Status = currentState // fallback to to old state
		}

		ev.Push(finalEvent)
		return nil
	}

	return k.coreMethods(r, buildFunc)
}

func (k *Kloud) Destroy(r *kite.Request) (resp interface{}, reqErr error) {
	destroyFunc := func(ctx context.Context, machine interface{}) error {
		ev, ok := eventer.FromContext(ctx)
		if !ok {
			return fmt.Errorf("eventer context is not available")
		}

		ev.Push(&eventer.Event{
			Message: "Terminating started",
			Status:  machinestate.Terminating,
		})

		destroyer, ok := machine.(Destroyer)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		stater, ok := machine.(Stater)
		if !ok {
			return NewError(ErrStaterNotImplemented)
		}
		currentState := stater.State()

		finalEvent := &eventer.Event{
			Message:    "Terminating finished",
			Status:     machinestate.Terminated,
			Percentage: 100,
		}

		err := destroyer.Destroy(ctx)
		if err != nil {
			finalEvent.Error = "Terminating failed. Please contact support."
			finalEvent.Status = currentState
		}

		ev.Push(finalEvent)
		return nil
	}

	return k.coreMethods(r, destroyFunc)
}

func (k *Kloud) Start(r *kite.Request) (resp interface{}, reqErr error) {
	startFunc := func(ctx context.Context, machine interface{}) error {
		// special case `NetworkOut` error since client relies on this
		// to show a modal
		// if strings.Contains(err.Error(), "NetworkOut") {
		// 	msg = err.Error()
		// }

		// special case `plan is expired` error since client relies on this
		// to show a modal
		// if strings.Contains(strings.ToLower(err.Error()), "plan is expired") {
		// 	msg = err.Error()
		// }
		return nil
	}

	return k.coreMethods(r, startFunc)
}

func (k *Kloud) Stop(r *kite.Request) (resp interface{}, reqErr error) {
	stopFunc := func(ctx context.Context, machine interface{}) error {
		ev, ok := eventer.FromContext(ctx)
		if !ok {
			return fmt.Errorf("eventer context is not available")
		}

		ev.Push(&eventer.Event{
			Message: "Machine is stopping",
			Status:  machinestate.Stopping,
		})

		stopper, ok := machine.(Stopper)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		stater, ok := machine.(Stater)
		if !ok {
			return NewError(ErrStaterNotImplemented)
		}
		currentState := stater.State()

		finalEvent := &eventer.Event{
			Message:    "Stopping finished",
			Status:     machinestate.Stopped,
			Percentage: 100,
		}

		err := stopper.Stop(ctx)
		if err != nil {
			finalEvent.Error = "Stopping failed. Please contact support."
			finalEvent.Status = currentState
		}

		ev.Push(finalEvent)
		return nil
	}

	return k.coreMethods(r, stopFunc)
}
