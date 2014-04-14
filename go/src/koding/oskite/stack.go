package oskite

import (
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
)

type Templater interface {
	Create() error
}

func vmCreateOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmCreate(vos)
}

func vmCreate(vos *virt.VOS) (interface{}, error) {
	if !vos.Permissions.Sudo {
		return nil, &kite.PermissionError{}
	}

	return nil, nil
}
