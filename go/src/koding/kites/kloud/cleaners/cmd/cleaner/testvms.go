package main

import (
	"errors"
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
)

type TestVMS struct {
	instances lookup.MultiInstances
}

func (t *TestVMS) Process() error {
	if t.instances.Total() == 0 {
		return errors.New("testvms: no VMs found")
	}

	t.instances.TerminateAll()
	return nil
}

func (t *TestVMS) Print() {
	fmt.Printf("testvms: terminated '%d' instances\n", t.instances.Total())
}
