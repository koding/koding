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
	vms := make([]virt.VM, 0)

	query := func(c *mgo.Collection) error {
		vm := virt.VM{}

		iter := c.Find(bson.M{"hostKite": o.ServiceUniquename}).Batch(50).Iter()
		for iter.Next(&vm) {
			vms = append(vms, vm)

			if !blacklist.Has(vm.Id.Hex()) {
				o.startAlwaysOn(vm)
				continue
			}
		}

		return iter.Close()
	}

	for _ = range time.Tick(time.Second * 30) {
		// start alwaysOn Vms
		if err := mongodbConn.Run("jVMs", query); err != nil {
			log.Error("allVMs fetching err: %s", err.Error())
		}

		// batch update the states now
		currentStates := make(map[bson.ObjectId]string, 0)

		for _, vm := range vms {
			log.Info("[updater] getting state for VM [%s - %s]", vm.Id, vm.HostnameAlias)

			state, err := vm.GetState()
			if err != nil {
				log.Error("[updater] getting state failed for VM [%s - %s], err: %s", vm.Id, vm.HostnameAlias, err)
			}

			// do not update if it's the same state
			if vm.State == state {
				continue
			}

			currentStates[vm.Id] = state
		}

		filter := func(desiredState string) []bson.ObjectId {
			ids := make([]bson.ObjectId, 0)

			for id, state := range currentStates {
				if state == desiredState {
					ids = append(ids, id)
				}
			}

			return ids
		}

		if err := updateStates(filter("RUNNING"), "RUNNING"); err != nil {
			log.Error("Updating RUNNING vms %v", err)
		}

		if err := updateStates(filter("STOPPED"), "STOPPED"); err != nil {
			log.Error("Updating STOPPED vms %v", err)
		}

		if err := updateStates(filter("UNKNOWN"), "UNKNOWN"); err != nil {
			log.Error("Updating UNKNOWN vms %v", err)
		}

		currentStates = nil // garbage collection

		// re initialize for next iteration
		vms = make([]virt.VM, 0)
	}

}

// updateStates updates the state field of the given ids to the given state argument.
func updateStates(ids []bson.ObjectId, state string) error {
	if len(ids) == 0 {
		return nil // no need to update
	}

	log.Info("Updating %d vms to the state %s", len(ids), state)

	// let others know that we started to work on updating
	updateWaitGroup.Add(1)

	err := mongodbConn.Run("jVMs", func(c *mgo.Collection) error {
		_, err := c.UpdateAll(
			bson.M{"_id": bson.M{"$in": ids}},
			bson.M{"$set": bson.M{"state": state}},
		)
		return err
	})

	// ok we finished now, let others know that we have finished now
	updateWaitGroup.Done()
	return err
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
		if vm.State != "RUNNING" && vm.State != "UNKNOWN" {
			log.Info("alwaysOn is starting [%s - %v]", vm.HostnameAlias, vm.Id)
			err := o.startSingleVM(vm, nil)
			if err != nil {
				log.Error("alwaysOn vm %s couldn't be started. err: %v", vm.HostnameAlias, err)
			} else {
				log.Info("alwaysOn vm started successfull [%s - %v]", vm.HostnameAlias, vm.Id)
			}
		}
	}()
}
