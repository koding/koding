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

// func (k *Kloud) Resize(r *kite.Request) (reqResp interface{}, reqErr error) {
// 	resizeFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		resp, err := p.Resize(m)
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
// 		err = k.Storage.Update(m.Id, &StorageData{
// 			Type: "resize",
// 			Data: map[string]interface{}{
// 				"ipAddress":    resp.IpAddress,
// 				"domainName":   resp.DomainName,
// 				"instanceId":   resp.InstanceId,
// 				"instanceName": resp.InstanceName,
// 			},
// 		})
//
// 		if err != nil {
// 			k.Log.Error("[%s] updating data after resize method was not possible: %s",
// 				m.Id, err.Error())
// 		}
//
// 		return resp, nil
// 	}
//
// 	return k.coreMethods(r, resizeFunc)
// }
//
// func (k *Kloud) Restart(r *kite.Request) (resp interface{}, reqErr error) {
// 	restartFunc := func(m *protocol.Machine, p protocol.Provider) (interface{}, error) {
// 		err := p.Restart(m)
// 		return nil, err
// 	}
//
// 	return k.coreMethods(r, restartFunc)
// }
