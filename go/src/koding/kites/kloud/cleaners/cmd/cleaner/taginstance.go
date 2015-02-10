package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"strings"

	"github.com/mitchellh/goamz/ec2"
)

type TagInstances struct {
	Instances *lookup.MultiInstances
	MongoDB   *lookup.MongoDB
	Machines  map[string]lookup.MachineDocument

	untagged map[*ec2.EC2][]tagData
	err      error
}

type tagData struct {
	id   string
	tags []ec2.Tag
}

func (t *TagInstances) Process() {
	emptyInstances := lookup.NewMultiInstances()

	// first collect all untagged instances. We can untagged instances when
	// `instance.Tags` is empty
	t.Instances.Iter(func(client *ec2.EC2, instances lookup.Instances) {
		untaggedInstances := make(lookup.Instances, 0)

		for id, instance := range instances {
			// no tags available
			if len(instance.Tags) == 0 {
				untaggedInstances[id] = instance
			}
		}

		emptyInstances.Add(client, untaggedInstances)
	})

	// this is just here for debugging, remove once you are finished
	if emptyInstances.Total() > 50 {
		fmt.Printf("=============> tagInstances: oops there are '%d' untagged instances, something must be wrong\n",
			emptyInstances.Total())

		// log instance struct so we can see why this happened
		emptyInstances.Iter(func(client *ec2.EC2, instances lookup.Instances) {
			for _, instance := range instances {
				fmt.Printf("----------> [%s] instance = %+v tags %+v\n",
					client.Region.Name, instance, instance.Tags)
			}
		})
	}

	// next fetch the necessary tag data from MongoDB, so we can tag again the
	// untagged instances
	t.untagged = make(map[*ec2.EC2][]tagData, 0)
	emptyInstances.Iter(func(client *ec2.EC2, instances lookup.Instances) {
		regionUntagged := make([]tagData, 0)
		for id := range instances {
			// probably a ghost vm (an instance without a MongoDB document), we
			// don't care about it (this will be handled by the GhostVMs task
			// already)
			machine, ok := t.Machines[id]
			if !ok {
				continue
			}

			var instanceName string
			if i, ok := machine.Meta["instanceName"]; ok {
				if name, ok := i.(string); ok && name != "" {
					instanceName = name
				}
			}

			username := machine.Credential
			env := "production"
			machineId := machine.Id.Hex()
			domain := machine.Domain

			tags := []ec2.Tag{
				{Key: "Name", Value: instanceName},
				{Key: "koding-user", Value: username},
				{Key: "koding-env", Value: env},
				{Key: "koding-machineId", Value: machineId},
				{Key: "koding-domain", Value: domain},
			}

			regionUntagged = append(regionUntagged, tagData{
				id:   id,
				tags: tags,
			})
		}

		t.untagged[client] = regionUntagged
	})
}

func (t *TagInstances) Run() {
	count := 0
	for _, instances := range t.untagged {
		for _, _ = range instances {
			count++
		}
	}

	if count > 50 {
		fmt.Printf("tagInstances: count is '%d'. AWS response fetching failed. Aborting tagging instances\n", count)
	}

	for client, untaggedInstances := range t.untagged {
		for _, instance := range untaggedInstances {
			_, err := client.CreateTags([]string{instance.id}, instance.tags)
			if err != nil {
				fmt.Printf("tagInstances: creating tags err %s\n", err.Error())
			}
		}
	}
}

func (t *TagInstances) Result() string {
	if t.err != nil {
		return fmt.Sprintf("tagInstances: error '%s'", t.err.Error())
	}

	ids := []string{}
	for _, instances := range t.untagged {
		for _, instance := range instances {
			ids = append(ids, instance.id)
		}
	}

	if len(ids) == 0 {
		return ""
	}

	return fmt.Sprintf("tagged '%d' untagged instances: %s", len(ids), strings.Join(ids, ","))
}

func (t *TagInstances) Info() *taskInfo {
	return &taskInfo{
		Title: "TagInstances",
		Desc:  "Tag and sync untagged instances.",
	}
}
