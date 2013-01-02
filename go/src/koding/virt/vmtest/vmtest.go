package main

import (
	"koding/virt"
	"os"
)

func main() {
	name := os.Args[1]

	user, err := virt.FindUserByName(name)
	if err != nil {
		panic(err)
	}

	vm, format := virt.GetDefaultVM(user)
	vm.Prepare(format)
	//vm.Start()
	//vm.Stop()
	//vm.Shutdown()
}
