package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
)

type MultipleVMs struct {
	Cleaner       *Cleaner
	IsPaid        func(username string) bool
	UsersMultiple map[string][]lookup.MachineDocument
	Instances     lookup.MultiInstances

	multipleInstances lookup.MultiInstances
	err               error
}

func (m *MultipleVMs) Process() {
	instances := m.Instances.
		States("running").
		WithTag("koding-env", "production")

	freeUsersWithMultipleVMs := make(map[string][]lookup.MachineDocument, 0)
	for user, machines := range m.UsersMultiple {
		// if not paid user, add it to the map
		if !m.IsPaid(user) {
			freeUsersWithMultipleVMs[user] = machines
		}
	}

	datas := make([]*StopData, 0)
	ids := make([]string, 0)

	for username, machines := range freeUsersWithMultipleVMs {
		for _, machine := range machines {
			// there is no way this can panic because we fetch documents which
			// have instanceIds in it
			instanceId := machine.Meta["instanceId"].(string)

			// only add if there is an instanceId
			data := &StopData{
				id:         machine.Id,
				instanceId: instanceId,
				domain:     machine.Domain,
				ipAddress:  machine.IpAddress,
				username:   username,
				reason:     "Free user has more than two machines.",
			}

			ids = append(ids, instanceId)
			datas = append(datas, data)
		}
	}

	m.multipleInstances = instances.Only(ids...)
	if m.multipleInstances.Total() == 0 {
		return
	}

	// first stop all machines, this is a batch API call so it's more efficient
	m.multipleInstances.StopAll()

	for _, data := range datas {
		m.Cleaner.StopMachine(data)
	}
}

func (m *MultipleVMs) Result() string {
	if m.err != nil {
		return fmt.Sprintf("multipleVMs: error '%s'", m.err.Error())
	}

	return fmt.Sprintf("multipleVMs: stopped '%d' machines",
		m.multipleInstances.Total())
}
