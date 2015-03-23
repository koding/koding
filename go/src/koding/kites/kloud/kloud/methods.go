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
