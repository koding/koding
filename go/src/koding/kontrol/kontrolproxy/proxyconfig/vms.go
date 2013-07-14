package proxyconfig

import (
	"fmt"
	"koding/virt/models"
	"labix.org/v2/mgo/bson"
)

func (p *ProxyConfiguration) GetVM(hostname string) (models.VM, error) {
	vm := models.VM{}
	if err := p.Collection["vms"].Find(bson.M{"hostnameAlias": hostname}).One(&vm); err != nil {
		return vm, fmt.Errorf("vm for hostname %s is not found", hostname)
	}

	return vm, nil
}
