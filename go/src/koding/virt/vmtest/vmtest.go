package main

import (
	"fmt"
	"koding/virt"
)

func main() {
	//vm, err := virt.FromIP(10, 1, 0, 0)
	vm, err := virt.FindByName("neelance")
	if err != nil {
		fmt.Println(err)
		return
	}

	//packages := vm.ReadDpkgStatus("/var/lib/dpkg/status")
	//vm.WriteDpkgStatus(packages, "out")

	//users := vm.ReadPasswd("/etc/passwd")
	//vm.WritePasswd(users, "out")

	vm.Prepare()
	//vm.Start()
	//vm.Stop()
	//vm.Shutdown()
}
