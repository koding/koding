package koding

import (
	"fmt"
	"koding/db/mongodb"

	"github.com/koding/kloud/protocol"
	"github.com/koding/kloud/provider/amazon"
)

type CheckContext struct {
	api      *amazon.AmazonClient
	db       *mongodb.MongoDB
	username string
}

// Limiter checks the limits via the Check() method. It should simply return an
// error if the limitations are exceed.
type Limiter interface {
	Check(ctx *CheckContext) error
}

type multiLimiter []Limiter

func (m multiLimiter) Check(ctx *CheckContext) error {
	for _, limiter := range m {
		if err := limiter.Check(ctx); err != nil {
			return err
		}
	}

	return nil
}

func newMultiLimiter(limiter ...Limiter) Limiter {
	return multiLimiter(limiter)
}

// Limit implements the kloud.Limiter interface
func (p *Provider) Limit(opts *protocol.MachineOptions, method string) error {
	// only check for build method, all other's are ok to be used without any
	// restriction.
	if method != "build" {
		return nil
	}

	a, err := p.NewClient(opts)
	if err != nil {
		return err
	}

	ctx := &CheckContext{
		api:      a,
		db:       p.DB,
		username: opts.Username,
	}

	return p.CheckLimits("free", ctx)
}

// CheckLimits checks the given user limits
func (p *Provider) CheckLimits(plan string, ctx *CheckContext) error {
	l, ok := limits[plan]
	if !ok {
		fmt.Errorf("plan %s not found", plan)
	}

	return l.Check(ctx)
}
