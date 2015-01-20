package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"time"
)

type LongRunning struct {
	Instances lookup.MultiInstances
	MongoDB   *lookup.MongoDB
	IsPaid    func(username string) bool
	Cleaner   *Cleaner

	runningInstances     lookup.MultiInstances
	longRunningInstances lookup.MultiInstances
	err                  error
}

func (l *LongRunning) Process() {
	l.runningInstances = l.Instances.
		OlderThan(12*time.Hour).
		States("running").
		WithTag("koding-env", "production")

	machines, err := l.MongoDB.Machines(l.runningInstances.Ids()...)
	if err != nil {
		l.err = err
		return
	}

	stopData := make([]*StopData, 0)
	ids := make([]string, 0)
	for _, machine := range machines {
		username := machine.Credential
		// if user is a paying customer skip it
		if l.IsPaid(username) {
			continue
		}

		// there is no way this can panic because we fetch documents which
		// have instanceIds in it
		instanceId := machine.Meta["instanceId"].(string)

		data := &StopData{
			id:         machine.Id,
			instanceId: instanceId,
			domain:     machine.Domain,
			ipAddress:  machine.IpAddress,
			username:   username,
			reason:     "Non free user, VM is running for more than 12 hours",
		}

		stopData = append(stopData, data)
		ids = append(ids, instanceId)

		// debug
		// fmt.Printf("[%s] %s %s %s\n", data.username, data.instanceId, data.domain, data.ipAddress)
	}

	// contains free user VMs running for more than 12 hours
	l.longRunningInstances = l.runningInstances.Only(ids...)
	if l.longRunningInstances.Total() == 0 {
		return
	}

	// first stop all machines, this is a batch API call so it's more efficient
	l.longRunningInstances.StopAll()

	for _, data := range stopData {
		l.Cleaner.StopMachine(data)
	}
}

func (l *LongRunning) Result() string {
	if l.err != nil {
		return fmt.Sprintf("longRunningVMs: error '%s'", l.err.Error())
	}

	return fmt.Sprintf("longRunningVMS: stopped '%d' free user instances",
		l.longRunningInstances.Total())
}
