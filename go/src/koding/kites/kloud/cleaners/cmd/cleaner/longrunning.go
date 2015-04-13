package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"strings"
	"time"
)

type LongRunning struct {
	Instances *lookup.MultiInstances
	MongoDB   *lookup.MongoDB
	IsPaid    func(username string) bool
	Cleaner   *Cleaner

	runningInstances     *lookup.MultiInstances
	longRunningInstances *lookup.MultiInstances
	err                  error
	stopData             map[string]*StopData
}

func (l *LongRunning) Process() {
	l.runningInstances = l.Instances.
		OlderThan(6*time.Hour).
		States("running").
		WithTag("koding-env", "production")

	machines, err := l.MongoDB.Machines(l.runningInstances.Ids()...)
	if err != nil {
		l.err = err
		return
	}

	stopData := make(map[string]*StopData, 0)
	ids := make([]string, 0)
	for _, machine := range machines {
		username := machine.Credential
		// if user is a paying customer skip it
		if l.IsPaid(username) {
			continue
		}

		i, ok := machine.Meta["instanceId"]
		if !ok {
			continue
		}

		instanceId, ok := i.(string)
		if !ok {
			continue
		}

		if instanceId == "" {
			continue
		}

		data := &StopData{
			id:         machine.Id,
			instanceId: instanceId,
			domain:     machine.Domain,
			ipAddress:  machine.IpAddress,
			username:   username,
			reason:     "Non free user, VM is running for more than 6 hours",
		}

		stopData[instanceId] = data
		ids = append(ids, instanceId)

		// debug
		// fmt.Printf("[%s] %s %s %s\n", data.username, data.instanceId, data.domain, data.ipAddress)
	}

	// contains free user VMs running for more than 6 hours
	l.longRunningInstances = l.runningInstances.Only(ids...)

	// filter out data from instances that are not running anymore
	l.stopData = make(map[string]*StopData, 0)
	for _, id := range l.longRunningInstances.Ids() {
		data, ok := stopData[id]
		if !ok {
			continue
		}

		l.stopData[id] = data
	}
}

func (l *LongRunning) Run() {
	if l.longRunningInstances.Total() == 0 {
		return
	}

	// first stop all machines, this is a batch API call so it's more efficient
	l.longRunningInstances.StopAll()

	for _, data := range l.stopData {
		l.Cleaner.StopMachine(data)
	}
}

func (l *LongRunning) Result() string {
	if l.err != nil {
		return fmt.Sprintf("longRunningVMs: error '%s'", l.err.Error())
	}

	if l.longRunningInstances.Total() == 0 {
		return ""
	}

	usernames := make([]string, 0)
	for _, data := range l.stopData {
		usernames = append(usernames, data.username)
	}

	return fmt.Sprintf("stopped '%d' free user instances. users: '%s'",
		l.longRunningInstances.Total(), strings.Join(usernames, ","))

}

func (l *LongRunning) Info() *taskInfo {
	return &taskInfo{
		Title: "LongRunningVms",
		Desc:  "Stop free VMs running for more than 6 hours",
	}
}
