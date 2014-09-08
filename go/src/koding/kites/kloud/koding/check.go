package koding

import (
	"fmt"

	"github.com/koding/kloud/api/amazon"
	"github.com/mitchellh/goamz/ec2"
)

type totalLimit struct {
	// total defines how much machines a user can have
	total int
}

type concurrentLimit struct {
	// concurrent defines how many machines can be used per user
	concurrent int
}

var (
	// limits contains the various limitations based on the machine
	// itself.
	limits = map[string]Limiter{
		"free": freeLimiter(),
	}
)

/*
Free:  1 VM, 0 Always On, 30 min timeout -- CAN ONLY CREATE ONE t2.micro (1GB
RAM, 3GB Storage)

Hobbyist: 3 VMs, 0 Always On, 6 hour timeout -- t2.micros ONLY (1GB RAM, 3GB
Storage)

Developer: 3 VMs, 1 Always On, 3GB total RAM, 20GB total Storage, 12 hour
timeout  -- t2.micro OR t2.small  (variable Storage)

Professional: 5 VMs, 2 Always On, 5GB total RAM, 50GB total Storage, 12 hour
timeout  -- t2.micro OR t2.small OR t2.medium  (variable Storage)

Super: 10 VMs, 5 Always On, 10GB total RAM, 100GB total Storage, 12 hour
timeout  -- t2.micro OR t2.small OR t2.medium  (variable Storage)
*/

// freeLimiter defines a Limiter which is used for free plans
func freeLimiter() Limiter {
	// Non-paid user cannot create more than 3 VMs
	// Non-paid user cannot start more than 1 VM simultaneously
	return newMultiLimiter(
		&totalLimit{total: 1},
		&concurrentLimit{concurrent: 1},
	)
}

func (t *totalLimit) Check(ctx *CheckContext) error {
	filter := ec2.NewFilter()
	// instances in Amazon have a `koding-user` tag with the username as the
	// value. We can easily find them acording to this tag
	filter.Add("tag:koding-user", ctx.username)
	filter.Add("tag:koding-env", ctx.env)

	// Anything except "terminated" and "shutting-down"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	instances, err := ctx.api.InstancesByFilter(filter)

	// no match, allow to create instance
	if err == amazon.ErrNoInstances {
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	ctx.log.Info("Got %+v servers for user: %s\n", len(instances), ctx.username)

	if len(instances) >= t.total {
		ctx.log.Info("Total limit for the user %s is %d. Permission denied to create another one.", ctx.username, t.total)
		return fmt.Errorf("total limit of %d machines has been reached", t.total)
	}

	return nil
}

func (c *concurrentLimit) Check(ctx *CheckContext) error {
	return nil
}
