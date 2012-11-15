package main

import (
	"koding/tools/vm"
)

func main() {
	m := vm.Get(10, 1, 0, 0)
	//m.WriteConfig()

	//packages := vm.ReadDpkgStatus("/var/lib/dpkg/status")
	//vm.WriteDpkgStatus(packages, "out")

	//users := vm.ReadPasswd("/etc/passwd")
	//vm.WritePasswd(users, "out")

	m.Stop()
}
