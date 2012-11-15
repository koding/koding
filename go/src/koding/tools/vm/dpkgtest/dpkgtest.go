package main

import (
	"koding/tools/vm"
)

func main() {
	packages := vm.ReadDpkgStatusDB("/var/lib/dpkg/status")
	vm.WriteDpkgStatusDB(packages, "out")
}
