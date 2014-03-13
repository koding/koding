package modelhelper

import (
	"fmt"
	"koding/db/models"

	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

func NewVM() models.VM {
	return models.VM{
		Id:         bson.NewObjectId(),
		SnapshotVM: bson.NewObjectId(),
		IP:         nil,
	}
}

func GetVM(hostname string) (*models.VM, error) {
	vm := new(models.VM)
	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"hostnameAlias": hostname}).One(vm)
	}

	err := Mongo.Run("jVMs", query)
	if err != nil {
		return vm, fmt.Errorf("vm for hostname %s is not found", hostname)
	}

	return vm, nil
}

func GetUserVMS(username string) ([]*models.VM, error) {
	vm := new(models.VM)
	vms := make([]*models.VM, 0)

	query := func(c *mgo.Collection) error {
		iter := c.Find(bson.M{"webHome": username}).Iter()
		for iter.Next(&vm) {
			vms = append(vms, vm)
		}

		if err := iter.Close(); err != nil {
			return err
		}

		return nil
	}

	err := Mongo.Run("jVMs", query)
	if err != nil {
		return nil, fmt.Errorf("vm fetching err for user %s. err: %s", username, err)
	}

	return vms, nil
}

func AddVM(vm *models.VM) error {
	query := func(c *mgo.Collection) error {
		_, err := c.Upsert(bson.M{"hostnameAlias": vm.HostnameAlias}, &vm)
		if err != nil {
			return fmt.Errorf("AddVM error: %s", err)
		}
		return nil
	}

	return Mongo.Run("jVMs", query)
}

func DeleteVM(hostnameAlias string) error {
	query := func(c *mgo.Collection) error {
		return c.Remove(bson.M{"hostnameAlias": hostnameAlias})
	}

	return Mongo.Run("jVMs", query)
}
