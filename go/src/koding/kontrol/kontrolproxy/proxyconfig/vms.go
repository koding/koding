package proxyconfig

import (
	"fmt"
	"koding/virt/models"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func (p *ProxyConfiguration) GetVM(hostname string) (models.VM, error) {
	vm := models.VM{}
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"hostnameAlias": hostname}).One(&vm)
	}

	err := p.RunCollection("jVMs", query)
	if err != nil {
		return vm, fmt.Errorf("vm for hostname %s is not found", hostname)
	}

	return vm, nil
}
