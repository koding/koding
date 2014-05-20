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

// vmUpdater updates the states of current available VMs on the host machine.
func (o *Oskite) vmUpdater() {
	query := func(c *mgo.Collection) error {
		vm := &virt.VM{}

		iter := c.Find(bson.M{"hostKite": o.ServiceUniquename}).Batch(50).Iter()
		for iter.Next(&vm) {
			vmId := vm.Id
			if !blacklist.Has(vmId) {
				o.startAlwaysOn(vm) // it also checks if the vm is alwaysOn or not
			}

			if err := updateState(vmId, vm.State); err != nil {
				log.Error("vm update state %s err %v", vmId, err)
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

// startAlwaysOn  starts a vm if it's alwaysOn and not pinned to the current
// hostname
func (o *Oskite) startAlwaysOn(vm *virt.VM) {
	if !vm.AlwaysOn {
		return
	}

	// means this vm is intended to be start on another kontainer machine
	if vm.PinnedToHost != "" && vm.PinnedToHost != o.ServiceUniquename {
		return
	}

	go func() {
		err := o.startSingleVM(vm, nil)
		if err != nil {
			log.Error("alwaysOn vm %s couldn't be started. err: %v", vm.HostnameAlias, err)
		}
	}()
}

func unprepareLeftover(vmId bson.ObjectId) {
	prepareQueue <- &QueueJob{
		msg: fmt.Sprintf("unprepare leftover vm %s", vmId.Hex()),
		f: func() error {
			mockVM := &virt.VM{Id: vmId}
			if err := mockVM.Unprepare(nil, false); err != nil {
				log.Error("leftover unprepare: %v", err)
			}

			if err := updateState(vmId, ""); err != nil {
				log.Error("%v", err)
			}

			return nil
		},
	}
}
