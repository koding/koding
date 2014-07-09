package koding

import (
	"fmt"
	"time"
)

// Limiter checks the limits via the Check() method. It should simply return an
// error if the limitations are exceed.
type Limiter interface {
	Check() error
}

type limit struct {
	// total defines how much machines a user can have
	total int

	// concurrent defines how many machines can be used per user
	concurrent int

	// timeout defines the limit in which a machine can be RUNNING at most.
	// After the timeout is being reached, the machine is closed immediately.
	timeout time.Duration
}

var (
	// limits contains the various limitations for each plan
	limits = map[string]limit{
		// Non-paid user cannot create more than 3 VMs
		// Non-paid user cannot start more than 1 VM simultaneously
		// Non-paid user VM shuts down after 30 minutes without activity
		"free": {total: 3, concurrent: 1, timeout: 30 * time.Minute},
	}
)

func (l *limit) Check() error {
	return nil
}

// CheckLimits checks the given user limits
func (p *Provider) CheckLimits(plan string) error {
	l, ok := limits[plan]
	if !ok {
		fmt.Errorf("plan %s not found", plan)
	}

	return l.Check()
}
