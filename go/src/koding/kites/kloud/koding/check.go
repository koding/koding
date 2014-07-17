package koding

import (
	"fmt"
	"time"

	"github.com/koding/kloud/api/amazon"
)

type totalLimit struct {
	// total defines how much machines a user can have
	total int
}

type concurrentLimit struct {
	// concurrent defines how many machines can be used per user
	concurrent int
}

type timeoutLimit struct {
	// timeout defines the limit in which a machine can be RUNNING at most.
	// After the timeout is being reached, the machine is closed immediately.
	timeout time.Duration
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
	// Non-paid user VM shuts down after 30 minutes without activity
	return newMultiLimiter(
		&totalLimit{total: 3},
		&concurrentLimit{concurrent: 1},
		&timeoutLimit{timeout: 30 * time.Minute},
	)
}

func (t *totalLimit) Check(ctx *CheckContext) error {
	instances, err := ctx.api.InstancesByFilter("tag:koding-user", ctx.username)
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

func (t *timeoutLimit) Check(ctx *CheckContext) error {
	return nil
}
