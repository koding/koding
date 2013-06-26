package proxyconfig

import (
	"fmt"
	"koding/virt"
	"labix.org/v2/mgo/bson"
)

func (p *ProxyConfiguration) GetVM(hostname string) (virt.VM, error) {
	vm := virt.VM{}
	if err := p.Collection["vms"].Find(bson.M{"hostnameAlias": hostname}).One(&vm); err != nil {
		return vm, fmt.Errorf("vm for hostname %s is not found", hostname)
	}

	return vm, nil
}
