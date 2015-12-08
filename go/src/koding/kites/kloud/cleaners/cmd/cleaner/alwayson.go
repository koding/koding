package main

import (
	"fmt"
	"strings"

	"koding/db/models"
	"koding/kites/kloud/cleaners/lookup"
)

type AlwaysOn struct {
	MongoDB          *lookup.MongoDB
	IsPaid           func(username string) bool
	AlwaysOnMachines []models.Machine

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
}

func (a *AlwaysOn) Run() {
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

	if len(a.nonvalidUsers) == 0 {
		return ""
	}

	return fmt.Sprintf("disabled '%d' free machines. users: %s",
		len(a.nonvalidUsers), strings.Join(a.nonvalidUsers, ","))
}

func (a *AlwaysOn) Info() *taskInfo {
	return &taskInfo{
		Title: "AlwaysOn",
		Desc:  "Update free users jMachine 'alwaysOn' field to false",
	}
}
