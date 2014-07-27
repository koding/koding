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
	// limits contains the various limitations for each plan
	limits = map[string]Limiter{
		"free": freeLimiter(),
	}
)

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

	// Anything except "terminated" and "shutting-downg"
	filter.Add("instance-state-name", "pending", "running", "stopping", "stopped")

	instances, err := ctx.api.InstancesByFilter(filter)

	// allow to create instance
	if err == amazon.ErrNoInstances {
		return nil
	}

	// if it's something else don't allow it until it's solved
	if err != nil {
		return err
	}

	fmt.Printf("Got %+v servers for user: %s\n", len(instances), ctx.username)

	if len(instances) >= t.total {
		return fmt.Errorf("total limit of %d machines has been reached", t.total)
	}

	return nil
}

func (c *concurrentLimit) Check(ctx *CheckContext) error {
	return nil
}
