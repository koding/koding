package oskite

import (
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
)

type Templater interface {
	Create() error
}

type createParamsOld struct {
	OnProgress dnode.Callback
}

func (c *createParamsOld) Enabled() bool      { return c.OnProgress != nil }
func (c *createParamsOld) Call(v interface{}) { c.OnProgress(v) }

func vmCreateOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	params := new(createParamsOld)
	if args != nil && args.Unmarshal(&params) != nil {
		return nil, &kite.ArgumentError{Expected: "{OnProgress: [function]}"}
	}

	return vmCreate(params, vos)
}

func vmCreate(params progresser, vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	return progress(vos, "vm.create "+vos.VM.HostnameAlias, params, func() error {
		results := make(chan *virt.Step)
		go prepareProgress(results, vos)

		for step := range results {
			if params.Enabled() {
				params.Call(step)
			}

			if step.Err != nil {
				return step.Err
			}
		}

		return nil
	})
}
