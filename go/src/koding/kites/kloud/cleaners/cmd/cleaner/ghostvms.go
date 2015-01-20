package main

import (
	"fmt"
	"koding/kites/kloud/cleaners/lookup"
	"time"

	"github.com/mitchellh/goamz/ec2"
)

type GhostVMs struct {
	Instances *lookup.MultiInstances
	MongoDB   *lookup.MongoDB
	Ids       map[string]struct{}

	ghostInstances *lookup.MultiInstances
	err            error
}

func (g *GhostVMs) Process() {
	prodInstances := g.Instances.
		WithTag("koding-env", "production").
		OlderThan(time.Hour)

	g.ghostInstances = lookup.NewMultiInstances()

	prodInstances.Iter(func(client *ec2.EC2, vms lookup.Instances) {
		ghostIds := make(lookup.Instances, 0)

		for id, instance := range vms {
			_, ok := g.Ids[id]
			// so we have a id that is available on AWS but is not available in
			// MongodB
			if !ok {
				ghostIds[id] = instance
			}
		}

		g.ghostInstances.Add(client, ghostIds)
	})

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

	return fmt.Sprintf("ghostVMs: terminated '%d' instances",
		g.ghostInstances.Total())
}
