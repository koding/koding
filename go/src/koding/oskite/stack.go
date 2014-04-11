package oskite

import (
	"koding/tools/dnode"
	"koding/tools/kite"
	"koding/virt"
)

func vmCreateOld(args *dnode.Partial, c *kite.Channel, vos *virt.VOS) (interface{}, error) {
	return vmCreate(vos)
}

func vmCreate(vos *virt.VOS) (interface{}, error) {

	return nil, nil
}
