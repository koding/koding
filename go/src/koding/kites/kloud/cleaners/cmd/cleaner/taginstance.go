package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"

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
	ids := make([]string, 0)

	t.Instances.Iter(func(client *ec2.EC2, instances lookup.Instances) {
		untaggedInstances := make(lookup.Instances, 0)

		for id, instance := range instances {
			// no tags available
			if len(instance.Tags) == 0 {
				untaggedInstances[id] = instance
				ids = append(ids, id)
			}
		}

		emptyInstances.Add(client, untaggedInstances)
	})

	t.untagged = make(map[*ec2.EC2][]tagData, 0)
	emptyInstances.Iter(func(client *ec2.EC2, instances lookup.Instances) {
		regionUntagged := make([]tagData, 0)
		for id := range instances {
			machine, ok := t.Machines[id]
			if !ok {
				fmt.Println("not found in mongodb", id)
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
	for client, untaggedInstances := range t.untagged {
		for _, instance := range untaggedInstances {
			client.CreateTags([]string{instance.id}, instance.tags)
		}
	}
}

func (t *TagInstances) Result() string {
	if t.err != nil {
		return fmt.Sprintf("tagInstances: error '%s'", t.err.Error())
	}

	count := 0
	for _, tags := range t.untagged {
		for _, _ = range tags {
			count++
		}
	}

	return fmt.Sprintf("tagged '%d' untagged instances", count)
}

func (t *TagInstances) Info() *taskInfo {
	return &taskInfo{
		Title: "TagInstances",
		Desc:  "Tag and sync untagged instances.",
	}
}
