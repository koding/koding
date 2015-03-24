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

		finalEvent := &eventer.Event{
			Message:    "Building finished",
			Status:     machinestate.Running,
			Percentage: 100,
		}

		err := builder.Build(ctx)
		if err != nil {
			finalEvent.Error = "Build failed. Please contact support."
			finalEvent.Status = machinestate.NotInitialized
		}

		ev.Push(finalEvent)
		return nil
	}

	return k.coreMethods(r, buildFunc)
}

func (k *Kloud) Destroy(r *kite.Request) (resp interface{}, reqErr error) {
	destroyFunc := func(ctx context.Context, machine interface{}) error {
		destroyer, ok := machine.(Destroyer)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		return destroyer.Destroy(ctx)
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
