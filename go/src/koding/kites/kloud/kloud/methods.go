package kloud

import (
	"github.com/koding/kite"
	"golang.org/x/net/context"
)

func (k *Kloud) Build(r *kite.Request) (interface{}, error) {
	buildFunc := func(ctx context.Context, machine interface{}) error {
		builder, ok := machine.(Builder)
		if !ok {
			return NewError(ErrBuilderNotImplemented)
		}

		return builder.Build(ctx)
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
		starter, ok := machine.(Starter)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		// TODO: fix this out
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
		return starter.Start(ctx)
	}

	return k.coreMethods(r, startFunc)
}

func (k *Kloud) Stop(r *kite.Request) (resp interface{}, reqErr error) {
	stopFunc := func(ctx context.Context, machine interface{}) error {
		stopper, ok := machine.(Stopper)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		return stopper.Stop(ctx)
	}

	return k.coreMethods(r, stopFunc)
}

func (k *Kloud) Reinit(r *kite.Request) (resp interface{}, reqErr error) {
	reinitFunc := func(ctx context.Context, machine interface{}) error {
		reiniter, ok := machine.(Reiniter)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		return reiniter.Reinit(ctx)
	}

	return k.coreMethods(r, reinitFunc)
}

func (k *Kloud) Resize(r *kite.Request) (resp interface{}, reqErr error) {
	resizeFunc := func(ctx context.Context, machine interface{}) error {
		resizer, ok := machine.(Resizer)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		return resizer.Resize(ctx)
	}

	return k.coreMethods(r, resizeFunc)
}

func (k *Kloud) Restart(r *kite.Request) (resp interface{}, reqErr error) {
	restartFunc := func(ctx context.Context, machine interface{}) error {
		restart, ok := machine.(Restarter)
		if !ok {
			return NewError(ErrProviderNotImplemented)
		}

		return restart.Restart(ctx)
	}

	return k.coreMethods(r, restartFunc)
}
