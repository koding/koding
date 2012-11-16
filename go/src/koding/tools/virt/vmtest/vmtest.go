package main

import (
	"fmt"
	"koding/tools/virt"
)

func main() {
	//vm, err := virt.FromIP(10, 1, 0, 0)
	vm, err := virt.FromUsername("neelance")
	if err != nil {
		panic(err)
	}
	fmt.Println(vm.Username())

	//vm.Setup()

	//packages := vm.ReadDpkgStatus("/var/lib/dpkg/status")
	//vm.WriteDpkgStatus(packages, "out")

	//users := vm.ReadPasswd("/etc/passwd")
	//vm.WritePasswd(users, "out")

	//vm.Start()
	//vm.Stop()
	//vm.Shutdown()
}
