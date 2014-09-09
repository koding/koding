package koding

import (
	"fmt"
	"koding/db/mongodb"

	aws "github.com/koding/kloud/api/amazon"
	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
	"github.com/koding/logging"
	"github.com/mitchellh/goamz/ec2"
)

type PlanChecker struct {
	api      *amazon.AmazonClient
	db       *mongodb.MongoDB
	machine  *protocol.Machine
	username string
	env      string
	log      logging.Logger
}

// Plan returns the current plan
func (p *PlanChecker) Plan() (Plan, error) {
	return Free, nil
}

// Total checks whether the user has reached the current plan's limit of having
// a total number numbers of machines. It returns an error if the limit is
// reached or an unexplained error happaned.
func (p *PlanChecker) Total() error {
	plan, err := p.Plan()
	if err != nil {
		return err
	}

	allowedMachines := plan.Limits().Total

	filter := ec2.NewFilter()
	// instances in Amazon have a `koding-user` tag with the username as the
	// value. We can easily find them acording to this tag
	filter.Add("tag:koding-user", p.username)
	filter.Add("tag:koding-env", p.env)

	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	instances, err := p.api.InstancesByFilter(filter)

	// no match, allow to create instance
	if err == aws.ErrNoInstances {
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	if len(instances) >= allowedMachines {
		p.log.Info("[%s] denying user '%s'. Current machine count: %d, Total machine limit: %d",
			p.machine.MachineId, p.username, len(instances), allowedMachines)

		return fmt.Errorf("total limit of %d machines has been reached", allowedMachines)
	}

	p.log.Info("[%s] allowing user '%s'. Current machine count: %d, Total machine limit: %d",
		p.machine.MachineId, p.username, len(instances), allowedMachines)

	return nil
}

// PlanChecker creates and returns a new PlanChecker struct that is responsible
// of checking various pieces of informations based on a Plan
func (p *Provider) PlanChecker(opts *protocol.Machine, a *amazon.AmazonClient) *PlanChecker {
	ctx := &PlanChecker{
		api:      a,
		db:       p.Session,
		username: opts.Builder["username"].(string),
		env:      p.Kite.Config.Environment,
		log:      p.Log,
		machine:  opts,
	}

	return ctx
}
