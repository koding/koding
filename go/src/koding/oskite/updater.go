package oskite

import (
	"fmt"
	"io/ioutil"
	"koding/db/models"
	"strings"
	"time"

	"gopkg.in/fatih/set.v0"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
)

type VmCollection map[bson.ObjectId]*models.VM

// mongodbVMs returns a map of VMs that are bind to the given
// serviceUniquename/hostkite in mongodb
func mongodbVMs(serviceUniquename string) (VmCollection, error) {
	vms := make([]*models.VM, 0)

	query := func(c *mgo.Collection) error {
		return c.Find(bson.M{"hostKite": serviceUniquename}).All(&vms)
	}

	if err := mongodbConn.Run("jVMs", query); err != nil {
		return nil, fmt.Errorf("allVMs fetching err: %s", err.Error())
	}

	vmsMap := make(map[bson.ObjectId]*models.VM, len(vms))

	for _, vm := range vms {
		vmsMap[vm.Id] = vm
	}

	return vmsMap, nil
}

// Ids returns a set of VM ids
func (v VmCollection) Ids() set.Interface {
	ids := set.NewNonTS()

	for id := range v {
		ids.Add(id)
	}

	return ids
}

// currentVMS returns a set of VM ids on the current host machine with their
// associated mongodb objectid's taken from the directory name
func currentVMs() (set.Interface, error) {
	dirs, err := ioutil.ReadDir("/var/lib/lxc")
	if err != nil {
		return nil, fmt.Errorf("vmsList err %s", err)
	}

	vms := set.NewNonTS()
	for _, dir := range dirs {
		if !strings.HasPrefix(dir.Name(), "vm-") {
			continue
		}

		vmId := bson.ObjectIdHex(dir.Name()[3:])
		vms.Add(vmId)
	}

	return vms, nil
}

// vmUpdater updates the states of current available VMs on the host machine.
func (o *Oskite) vmUpdater() {
	for _ = range time.Tick(time.Second * 10) {
		currentIds, err := currentVMs()
		if err != nil {
			log.Error("vm updater getting current vms err %v", err)
			continue
		}

		vms, err := mongodbVMs(o.ServiceUniquename)
		if err != nil {
			log.Error("vm updater mongoDBVms failed err %v", err)
		}

		combined := set.Intersection(currentIds, vms.Ids())

		combined.Each(func(item interface{}) bool {
			vmId, ok := item.(bson.ObjectId)
			if !ok {
				return true
			}

			err := updateState(vmId)
			if err == nil {
				return true
			}

			log.Error("vm updater vmId %s err %v", vmId, err)
			if err != mgo.ErrNotFound {
				return true
			}

			// this is a leftover VM that needs to be unprepared
			log.Error("vm updater vmId %s err %v", vmId, err)
			unprepareLeftover(vmId)

			return true
		})
	}

}
