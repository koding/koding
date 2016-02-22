package main

import (
	"fmt"
	"koding/db/models"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/cleaners/lookup"
	"strings"
)

type TagInstances struct {
	Instances *lookup.MultiInstances
	MongoDB   *lookup.MongoDB
	Machines  map[string]models.Machine

	untagged map[*amazon.Client][]tagData
	err      error
}

type tagData struct {
	id   string
	tags map[string]string
}

func (t *TagInstances) Process() {
	emptyInstanceMap := make(map[*amazon.Client]lookup.Instances)

	// first collect all untagged instances. We can untagged instances when
	// `instance.Tags` is empty
	t.Instances.Iter(func(client *amazon.Client, instances lookup.Instances) {
		untaggedInstances := make(lookup.Instances, 0)

		for id, instance := range instances {
			// no tags available
			if len(instance.Tags) == 0 {
				untaggedInstances[id] = instance
			}
		}

		emptyInstanceMap[client] = untaggedInstances
	})

	emptyInstances := lookup.NewMultiInstancesMap(emptyInstanceMap)

	// this is just here for debugging, remove once you are finished
	if emptyInstances.Total() > 50 {
		fmt.Printf("=============> tagInstances: oops there are '%d' untagged instances, something must be wrong\n",
			emptyInstances.Total())

		// log instance struct so we can see why this happened
		emptyInstances.Iter(func(client *amazon.Client, instances lookup.Instances) {
			for _, instance := range instances {
				fmt.Printf("----------> [%s] instance = %+v tags %+v\n",
					client.Region, instance, instance.Tags)
			}
		})
	}

	// next fetch the necessary tag data from MongoDB, so we can tag again the
	// untagged instances
	t.untagged = make(map[*amazon.Client][]tagData, 0)
	emptyInstances.Iter(func(client *amazon.Client, instances lookup.Instances) {
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
			machineId := machine.ObjectId.Hex()
			domain := machine.Domain

			tags := map[string]string{
				"Name":             instanceName,
				"koding-user":      username,
				"koding-env":       env,
				"koding-machineId": machineId,
				"koding-domain":    domain,
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
		return
	}

	for client, untaggedInstances := range t.untagged {
		for _, instance := range untaggedInstances {
			err := client.AddTags(instance.id, instance.tags)
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

	if len(ids) > 50 {
		return fmt.Sprintf("aborted due high count '%d'", len(ids))
	}

	return fmt.Sprintf("tagged '%d' untagged instances: %s", len(ids), strings.Join(ids, ","))
}

func (t *TagInstances) Info() *taskInfo {
	return &taskInfo{
		Title: "TagInstances",
		Desc:  "Tag and sync untagged instances.",
	}
}
