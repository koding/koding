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
	Volumes   *lookup.MultiVolumes
	MongoDB   *lookup.MongoDB

	largeInstances *lookup.MultiInstances
	err            error
	stopData       map[string]*StopData
}

func (v *Volumes) Process() {
	largeVolumes := v.Volumes.GreaterThan(3)

	inUse := largeVolumes.Status("in-use")

	instances := v.Instances.
		States("running").
		OlderThan(time.Hour).
		WithTag("koding-env", "production")

	ids := make([]string, 0)
	stopData := make(map[string]*StopData, 0)

	for _, volumes := range inUse.Volumes() {
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
				id:         machine.ObjectId,
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
	v.largeInstances.StopAll()

	for _, data := range v.stopData {
		v.Cleaner.StopMachine(data)
	}
}

func (v *Volumes) Result() string {
	if v.err != nil {
		return fmt.Sprintf("volumes: error '%s'", v.err.Error())
	}

	var result string

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
