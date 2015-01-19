package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
)

type AlwaysOn struct {
	MongoDB          *lookup.MongoDB
	IsPaid           func(username string) bool
	AlwaysOnMachines []lookup.MachineDocument

	nonvalidUsers []string
	err           error
}

func (a *AlwaysOn) Process() {
	a.nonvalidUsers = make([]string, 0)

	for _, machine := range a.AlwaysOnMachines {
		username := machine.Credential

		// if user is not a paying customer
		if !a.IsPaid(username) {
			a.nonvalidUsers = append(a.nonvalidUsers, username)
		}
	}

	if len(a.nonvalidUsers) == 0 {
		return
	}

	if err := a.MongoDB.RemoveAlwaysOn(a.nonvalidUsers...); err != nil {
		a.err = err
	}
}

func (a *AlwaysOn) Result() string {
	if a.err != nil {
		return fmt.Sprintf("alwaysOn: error '%s'", a.err.Error())
	}
	return fmt.Sprintf("alwaysOn: disabled '%d' free machines", len(a.nonvalidUsers))
}
