package main

import (
	"koding/tools/lxc"
)

func main() {
	lxc.GetVM(10, 1, 0, 0).WriteConfig()
}
