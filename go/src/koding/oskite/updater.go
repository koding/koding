package oskite

import (
	"fmt"
	"koding/virt"
	"time"

	"gopkg.in/fatih/set.v0"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type VmCollection map[bson.ObjectId]*virt.VM

var blacklist = set.New()

// mongodbVMs returns a map of VMs that are bind to the given
// serviceUniquename/hostkite in mongodb
func mongodbVMs(serviceUniquename string) (VmCollection, error) {
	vms := make([]*virt.VM, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"hostKite": serviceUniquename}).All(&vms)
	}

	if err := mongodbConn.Run("jVMs", query); err != nil {
		return nil, fmt.Errorf("allVMs fetching err: %s", err.Error())
	}

	vmsMap := make(map[bson.ObjectId]*virt.VM, len(vms))

	for _, vm := range vms {
		vmsMap[vm.Id] = vm
	}

	return vmsMap, nil
}

// updateStates updates the state field of the given ids to the given state argument.
func updateStates(ids []string, state string) error {
	bsonIds := make([]bson.M, len(ids))
	for i, id := range ids {
		bsonIds[i] = bson.M{"id": bson.ObjectIdHex(id)}
	}

	return mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		return c.Update(bson.M{"$in": bsonIds}, bson.M{"$set": bson.M{"state": state}})
	})
}

// vmUpdater updates the states of current available VMs on the host machine.
func (o *Oskite) vmUpdater() {
	query := func(c *mgo.Collection) error {
		vm := virt.VM{}

		iter := c.Find(bson.M{"hostKite": o.ServiceUniquename}).Batch(50).Iter()
		for iter.Next(&vm) {
			if !blacklist.Has(vm.Id.Hex()) {
				o.startAlwaysOn(vm)
				continue
			}

			_, err := updateState(vm.Id, vm.State)
			if err != nil {
				log.Error("vm update state %s err %v", vm.Id.Hex(), err)
			}
		}

		return iter.Close()
	}

	for _ = range time.Tick(time.Second * 30) {
		if err := mongodbConn.Run("jVMs", query); err != nil {
			log.Error("allVMs fetching err: %s", err.Error())
		}
	}

}

func unprepareInQueue(vm *virt.VM) {
	prepareQueue <- &QueueJob{
		msg: fmt.Sprintf("Vm is stopped, unpreparing it: %s", vm.HostnameAlias),
		f: func() error {
			info := getInfo(vm)
			info.mutex.Lock()
			defer info.mutex.Unlock()

			return unprepareProgress(nil, vm, false)
		},
	}
}

// startAlwaysOn  starts a vm if it's alwaysOn and not pinned to the current
// hostname
func (o *Oskite) startAlwaysOn(vm virt.VM) {
	if !vm.AlwaysOn {
		return
	}

	// means this vm is intended to be start on another kontainer machine
	if vm.PinnedToHost != "" && vm.PinnedToHost != o.ServiceUniquename {
		return
	}

	go func() {
		log.Info("alwaysOn is starting [%s - %v]", vm.HostnameAlias, vm.Id)
		err := o.startSingleVM(vm, nil)
		if err != nil {
			log.Error("alwaysOn vm %s couldn't be started. err: %v", vm.HostnameAlias, err)
		} else {
			log.Info("alwaysOn vm started successfull [%s - %v]", vm.HostnameAlias, vm.Id)
		}
	}()
}
