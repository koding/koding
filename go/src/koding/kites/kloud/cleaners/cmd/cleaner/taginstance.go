package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"

	"github.com/mitchellh/goamz/ec2"
)

type TagInstances struct {
	Instances *lookup.MultiInstances
	untagged  *lookup.MultiInstances
}

func (t *TagInstances) Process() {
	untaggedInstances := make(lookup.Instances, 0)
	t.untagged = lookup.NewMultiInstances()

	t.Instances.Iter(func(client *ec2.EC2, instances lookup.Instances) {
		for id, instance := range instances {
			for _, tag := range instance.Tags {
				if tag.Key != "Name" {
					continue
				}

				if tag.Value == "" {
					untaggedInstances[id] = instance
				}
			}
		}

		t.untagged.Add(client, untaggedInstances)
	})

	total := t.untagged.Total()
	fmt.Printf("total = %+v\n", total)

	fmt.Printf("%s\n", t.untagged)

	t.untagged.Iter(func(client *ec2.EC2, instances lookup.Instances) {
		fmt.Printf("region = %+v\n", client.Region.Name)
		for id := range instances {
			fmt.Printf("\t%+v\n", id)
		}
	})
}

func (t *TagInstances) Run() {
}

func (t *TagInstances) Result() string {
	return ""
}

func (t *TagInstances) Info() *taskInfo {
	return &taskInfo{
		Title: "TagInstances",
		Desc:  "Tag and sync untagged instances.",
	}
}
