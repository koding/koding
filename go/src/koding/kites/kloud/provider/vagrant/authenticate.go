package vagrant

import (
	"koding/kites/kloud/kloud"

	"golang.org/x/net/context"
)

// Authenticate
//
// TODO(rjeczalik): call klients?
func (s *Stack) Authenticate(ctx context.Context) (interface{}, error) {
	var arg kloud.AuthenticateRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	result := make(map[string]bool, len(arg.Identifiers))

	for _, ident := range arg.Identifiers {
		result[ident] = true
	}

	return result, nil
}
