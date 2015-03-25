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

// func (k *Kloud) Reinit(r *kite.Request) (resp interface{}, reqErr error) {
// 	reinitFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		resp, err := p.Reinit(m)
// 		if err != nil {
// 			return nil, err
// 		}
//
// 		// some providers might provide empty information, therefore do not
// 		// update anything for them
// 		if resp == nil {
// 			return resp, nil
// 		}
//
// 		// if the username is not explicit changed, assign the original username to it
// 		if resp.Username == "" {
// 			resp.Username = m.Username
// 		}
//
// 		err = k.Storage.Update(m.Id, &StorageData{
// 			Type: "reinit",
// 			Data: map[string]interface{}{
// 				"ipAddress":    resp.IpAddress,
// 				"domainName":   resp.DomainName,
// 				"instanceId":   resp.InstanceId,
// 				"instanceName": resp.InstanceName,
// 				"queryString":  resp.KiteQuery,
// 			},
// 		})
//
// 		return resp, err
// 	}
//
// 	return k.coreMethods(r, reinitFunc)
// }
//
