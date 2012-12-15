package main

import (
	"koding/virt"
	"labix.org/v2/mgo"
	"os"
)

func main() {
	name := os.Args[1]

	vm, err := virt.FindByName(name)
	format := false
	if err == mgo.ErrNotFound {
		vm, err = virt.FetchUnused()
		if err != nil {
			panic(err)
		}
		vm.Name = name
		if err := virt.VMs.UpdateId(vm.Id, vm); err != nil {
			panic(err)
		}
		format = true
	}

	vm.Prepare(format)
	//vm.Start()
	//vm.Stop()
	//vm.Shutdown()
}
