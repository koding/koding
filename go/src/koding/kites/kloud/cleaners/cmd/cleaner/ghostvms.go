package main

import (
	"fmt"
	"strings"
	"time"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/cleaners/lookup"
)

type GhostVMs struct {
	Instances *lookup.MultiInstances
	Ids       map[string]lookup.MachineDocument

	ghostInstances *lookup.MultiInstances
	err            error
}

func (g *GhostVMs) Process() {
	gi := make(map[*amazon.Client]lookup.Instances)
	ut := make(map[*amazon.Client]lookup.Instances)

	prodInstances := g.Instances.
		WithTag("koding-env", "production").
		OlderThan(time.Hour)

	// pick 4 days old VMs. Why? Because if something goes wrong during weekend
	// (starting at Friday), we should be able to pick it up on Monday
	oldInstances := g.Instances.OlderThan(time.Hour * 96)

	prodInstances.Iter(func(client *amazon.Client, instances lookup.Instances) {
		ghostIds := make(lookup.Instances, 0)

		for id, instance := range instances {
			_, ok := g.Ids[id]
			// so we have a id that is available on AWS but is not available in
			// MongodB
			if !ok {
				ghostIds[id] = instance
			}
		}
		gi[client] = ghostIds
	})

	oldInstances.Iter(func(client *amazon.Client, instances lookup.Instances) {
		ghostIds := make(lookup.Instances, 0)

		for id, instance := range instances {
			if len(instance.Tags) != 0 {
				continue
			}

			_, ok := g.Ids[id]
			// so we have a id that is available on AWS but is not available in
			// MongodB, plus it's not tagged!
			if !ok {
				ghostIds[id] = instance
			}
		}
		ut[client] = ghostIds
	})

	g.ghostInstances = lookup.MergeMultiInstances(gi, ut)
}

func (g *GhostVMs) Run() {
	if g.ghostInstances.Total() > 100 {
		g.err = fmt.Errorf("didn't terminate anything, found more than '%d' host instances. Go and terminate it manually!", g.ghostInstances.Total())
		return
	}

	if g.ghostInstances.Total() == 0 {
		return
	}

	g.ghostInstances.TerminateAll()
}

func (g *GhostVMs) Result() string {
	if g.err != nil {
		return fmt.Sprintf("ghostVMs: error '%s'", g.err.Error())
	}

	if g.ghostInstances.Total() == 0 {
		return ""
	}

	return fmt.Sprintf("terminated '%d' instances. instances: %s",
		g.ghostInstances.Total(), strings.Join(g.ghostInstances.Ids(), ","))
}

func (g *GhostVMs) Info() *taskInfo {
	return &taskInfo{
		Title: "GhostVMs",
		Desc:  "Terminate production instances without any jMachine document",
	}
}
