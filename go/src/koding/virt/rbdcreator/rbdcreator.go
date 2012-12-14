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
		available, err := virt.VMs.Find(virt.VM{Used: false}).Count()
		if err != nil {
			panic(err)
		}

		fmt.Println(available)
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
				device := "/dev/rbd/rbd/" + vm.String()
				for {
					_, err := os.Stat(device)
					if err == nil {
						break
					}
					if !os.IsNotExist(err) {
						panic(err)
					}
					time.Sleep(1)
				}
				time.Sleep(3)

				// create file system
				if err = exec.Command("mkfs.ext4", device).Run(); err != nil {
					panic(err)
				}

				// mount, change user and umount
				tmpDir := fmt.Sprintf("/tmp/rbdcreator%d", newId)
				if err := os.Mkdir(tmpDir, 0755); err != nil {
					panic(err)
				}
				defer os.Remove(tmpDir)

				if err := exec.Command("/bin/mount", device, tmpDir).Run(); err != nil {
					panic(err)
				}
				defer exec.Command("/bin/umount", tmpDir).Run()

				if err := os.Chown(tmpDir, virt.VMROOT_ID, virt.VMROOT_ID); err != nil {
					panic(err)
				}
				if err := os.Remove(tmpDir + "/lost+found"); err != nil {
					panic(err)
				}

				// insert into database
				if err := virt.VMs.Insert(vm); err != nil {
					panic(err)
				}
				fmt.Println("created", newId)
			}()
		}

		time.Sleep(10 * time.Second)
	}
}

func FindMaxId() int {
	var vm virt.VM
	err := virt.VMs.Find(bson.M{}).Sort("-_id").One(&vm)
	if err != nil {
		if err == mgo.ErrNotFound {
			return 1<<16 - 1
		}
		panic(err)
	}
	return vm.Id
}
