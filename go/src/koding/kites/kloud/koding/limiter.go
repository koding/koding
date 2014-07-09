package koding

import "github.com/koding/kloud/provider/openstack"

type CheckContext struct {
	api      *openstack.OpenstackClient
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
