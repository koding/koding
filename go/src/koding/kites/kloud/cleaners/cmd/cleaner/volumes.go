package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"time"
)

type Volumes struct {
	Cleaner   *Cleaner
	IsPaid    func(username string) bool
	Instances lookup.MultiInstances
	Volumes   lookup.MultiVolumes
	MongoDB   *lookup.MongoDB

	notusedVolumes lookup.MultiVolumes
	largeInstances lookup.MultiInstances
	err            error
}

func (v *Volumes) Process() {
	largeVolumes := v.Volumes.GreaterThan(3)

	inUse := largeVolumes.Status("in-use")
	v.notusedVolumes = largeVolumes.Status("available").OlderThan(time.Hour)

	done := make(chan bool)
	go func() {
		if v.notusedVolumes.Total() > 0 {
			v.notusedVolumes.TerminateAll()
		}

		close(done)
	}()

	instances := v.Instances.
		States("running").
		OlderThan(time.Hour).
		WithTag("koding-env", "production")

	ids := make([]string, 0)
	datas := make([]*StopData, 0)

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
			if !v.IsPaid(username) {
				continue
			}

			// there is no way this can panic because we fetch documents which
			// have instnaceIds in it
			instanceId := machine.Meta["instanceId"].(string)
			volumeId := volIds[instanceId]
			size := volumes[volumeId].Size

			data := &StopData{
				id:         machine.Id,
				instanceId: instanceId,
				domain:     machine.Domain,
				ipAddress:  machine.IpAddress,
				username:   username,
				reason:     "Free user has more than one machines.",
			}

			fmt.Printf("username = %+v size: %s volId: %v\n", username, size, volumeId)

			ids = append(ids, instanceId)
			datas = append(datas, data)
		}
	}

	v.largeInstances = instances.Only(ids...)
	if v.largeInstances.Total() == 0 {
		return
	}

	// TODO: enable once we have a filter to stop Koding based users
	// v.largeInstances.StopAll()
	//
	// for _, data := range datas {
	// 	v.Cleaner.StopMachine(data)
	// }

	fmt.Printf("found = %+v\n", v.largeInstances.Total())
	for _, data := range datas {
		fmt.Printf("[%s] username = %+v\n", data.id, data.username)
	}

	<-done // wait for terminatin not unused volumes
}

func (v *Volumes) Result() string {
	return fmt.Sprintf("volumes: terminated '%d' not used volumes",
		v.notusedVolumes.Total())
}
