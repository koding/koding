package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"strings"
	"time"
)

type Volumes struct {
	Cleaner   *Cleaner
	IsPaid    func(username string) bool
	Instances *lookup.MultiInstances
	Volumes   lookup.MultiVolumes
	MongoDB   *lookup.MongoDB

	notusedVolumes lookup.MultiVolumes
	largeInstances *lookup.MultiInstances
	err            error
	stopData       map[string]*StopData
}

func (v *Volumes) Process() {
	largeVolumes := v.Volumes.GreaterThan(3)

	inUse := largeVolumes.Status("in-use")
	v.notusedVolumes = largeVolumes.Status("available").OlderThan(time.Hour)

	instances := v.Instances.
		States("running").
		OlderThan(time.Hour).
		WithTag("koding-env", "production")

	ids := make([]string, 0)
	stopData := make(map[string]*StopData, 0)

	for _, volumes := range inUse {
		volIds := volumes.InstanceIds()

		instanceIds := make([]string, 0)
		for instanceId := range volIds {
			instanceIds = append(instanceIds, instanceId)
		}

		machines, err := v.MongoDB.Machines(instanceIds...)
		if err != nil {
			v.err = err
			return // return and don't continue
		}

		for _, machine := range machines {
			username := machine.Credential

			// if user is not a paying customer just continue, we don't care
			if v.IsPaid(username) {
				continue
			}

			// there is no way this can panic because we fetch documents which
			// have instnaceIds in it
			instanceId := machine.Meta["instanceId"].(string)

			if s, ok := machine.Meta["storage_size"]; ok {
				if storageSize, ok := s.(int); ok {
					volId := volIds[instanceId]
					volSize := volumes.SizeFromVolumeId(volId)

					// The maximum storage a free user can have is 10 gig, 3
					// from the default storage and 7 from referrals. If the storage
					if storageSize <= 10 && volSize != 0 && volSize <= storageSize {
						continue
					}
				}
			}

			data := &StopData{
				id:         machine.Id,
				instanceId: instanceId,
				domain:     machine.Domain,
				ipAddress:  machine.IpAddress,
				username:   username,
				reason:     "Free user has more than one machines.",
			}

			ids = append(ids, instanceId)
			stopData[instanceId] = data
		}
	}

	v.largeInstances = instances.Only(ids...)
	v.stopData = make(map[string]*StopData, 0)
	for _, id := range v.largeInstances.Ids() {
		data, ok := stopData[id]
		if !ok {
			continue
		}

		v.stopData[id] = data
	}
}

func (v *Volumes) Run() {
	done := make(chan bool)
	go func() {
		if v.notusedVolumes.Total() > 0 {
			v.notusedVolumes.TerminateAll()
		}

		close(done)
	}()

	v.largeInstances.StopAll()

	for _, data := range v.stopData {
		v.Cleaner.StopMachine(data)
	}

	<-done // wait for terminating not unused volumes
}

func (v *Volumes) Result() string {
	if v.err != nil {
		return fmt.Sprintf("volumes: error '%s'", v.err.Error())
	}

	var result string
	if v.notusedVolumes.Total() != 0 {
		result = fmt.Sprintf("terminated '%d' not used volumes. ",
			v.notusedVolumes.Total())
	}

	if v.largeInstances.Total() != 0 {
		usernames := make([]string, 0)
		for _, data := range v.stopData {
			usernames = append(usernames, data.username)
		}

		result += fmt.Sprintf("stopped '%d' free machines. users: '%s'",
			v.largeInstances.Total(), strings.Join(usernames, ","))
	}

	return result
}

func (v *Volumes) Info() *taskInfo {
	return &taskInfo{
		Title: "Volumes",
		Desc:  "Terminate non used volumes. Stop VMs of non paying customers with volumes larger than 3GB",
	}
}
