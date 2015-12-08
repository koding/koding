package main

import (
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/cleaners/lookup"
	"strings"
	"time"
)

type MultipleVMs struct {
	Cleaner       *Cleaner
	IsPaid        func(username string) bool
	UsersMultiple map[string][]models.Machine
	Instances     *lookup.MultiInstances

	multipleInstances *lookup.MultiInstances
	err               error
	stopData          map[string]*StopData
}

func (m *MultipleVMs) Process() {
	instances := m.Instances.
		States("running").
		OlderThan(time.Hour).
		WithTag("koding-env", "production")

	freeUsersWithMultipleVMs := make(map[string][]models.Machine, 0)
	for user, machines := range m.UsersMultiple {
		// if not paid user, add it to the map
		if !m.IsPaid(user) {
			freeUsersWithMultipleVMs[user] = machines
		}
	}

	stopData := make(map[string]*StopData, 0)
	ids := make([]string, 0)

	for username, machines := range freeUsersWithMultipleVMs {
		for _, machine := range machines {
			// there is no way this can panic because we fetch documents which
			// have instanceIds in it
			instanceId := machine.Meta["instanceId"].(string)

			// only add if there is an instanceId
			data := &StopData{
				id:         machine.ObjectId,
				instanceId: instanceId,
				domain:     machine.Domain,
				ipAddress:  machine.IpAddress,
				username:   username,
				reason:     "Free user has more than two machines.",
			}

			stopData[instanceId] = data
			ids = append(ids, instanceId)
		}
	}

	m.multipleInstances = instances.Only(ids...)
	m.stopData = make(map[string]*StopData, 0)
	for _, id := range m.multipleInstances.Ids() {
		data, ok := stopData[id]
		if !ok {
			continue
		}

		m.stopData[id] = data
	}
}

func (m *MultipleVMs) Run() {
	if m.multipleInstances.Total() == 0 {
		return
	}

	// first stop all machines, this is a batch API call so it's more efficient
	m.multipleInstances.StopAll()

	for _, data := range m.stopData {
		m.Cleaner.StopMachine(data)
	}
}

func (m *MultipleVMs) Result() string {
	if m.err != nil {
		return fmt.Sprintf("multipleVMs: error '%s'", m.err.Error())
	}

	if m.multipleInstances.Total() == 0 {
		return ""
	}

	usernames := make([]string, 0)
	for _, data := range m.stopData {
		usernames = append(usernames, data.username)
	}

	return fmt.Sprintf("stopped '%d' machines. users: '%s'",
		m.multipleInstances.Total(), strings.Join(usernames, ","))
}

func (m *MultipleVMs) Info() *taskInfo {
	return &taskInfo{
		Title: "MultipleVMs",
		Desc:  "Stop VMs of non paying customers with more than one machine",
	}
}
