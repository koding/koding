package main

import (
	"fmt"

	"github.com/lxc/go-lxc"
)

func main() {

	defaultPath := lxc.DefaultConfigPath()
	for i, container := range lxc.DefinedContainers(defaultPath) {
		fmt.Println("[%d] name: %d", i, container.Name)
	}

}
