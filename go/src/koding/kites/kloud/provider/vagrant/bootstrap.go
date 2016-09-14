package vagrant

import (
	"koding/kites/kloud/stack"

	"golang.org/x/net/context"
)

// Bootstrap
func (s *Stack) Bootstrap(ctx context.Context) (interface{}, error) {
	var arg stack.BootstrapRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	// Vagrant currently requires no bootstrap.
	return true, nil
}
