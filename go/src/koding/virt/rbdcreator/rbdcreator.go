package main

import (
	"fmt"
	"koding/virt"
	"labix.org/v2/mgo"
	"labix.org/v2/mgo/bson"
	"os"
	"os/exec"
	"time"
)

var THRESHOLD = 100

func main() {
	nextId := FindMaxId() + 1

	for {
		available, err := virt.VMs.Find(bson.M{"used": false}).Count()
		if err != nil {
			panic(err)
		}

		fmt.Printf("available: %d\n", available)
		for i := 0; i < THRESHOLD-available; i++ {
			newId := nextId
			nextId++
			go func() {
				vm := virt.VM{Id: newId, Name: fmt.Sprintf("guest%d", newId), Used: false}

				// create disk and map to pool
				if err := exec.Command("/usr/bin/rbd", "create", vm.String(), "--size", "1200").Run(); err != nil {
					panic(err)
				}
				if err = exec.Command("/usr/bin/rbd", "map", vm.String(), "--pool", "rbd").Run(); err != nil {
					panic(err)
				}

				// wait for device to appear
				for {
					_, err := os.Stat(vm.RbdDevice())
					if err == nil {
						break
					}
					if !os.IsNotExist(err) {
						panic(err)
					}
					time.Sleep(1)
				}
				time.Sleep(3)

				// insert into database
				if err := virt.VMs.Insert(vm); err != nil {
					panic(err)
				}
			}()
		}

		time.Sleep(10 * time.Second)
	}
}

func FindMaxId() int {
	var vm virt.VM
	if err := virt.VMs.Find(nil).Sort("-_id").One(&vm); err != nil {
		if err == mgo.ErrNotFound {
			return 1<<16 - 1
		}
		panic(err)
	}
	return vm.Id
}
