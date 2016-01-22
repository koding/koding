package vagrant

import (
	"errors"
	"fmt"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/kloud"

	"golang.org/x/net/context"
)

// Authenticate
func (s *Stack) Authenticate(ctx context.Context) (interface{}, error) {
	var arg kloud.AuthenticateRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	if err := s.Builder.BuildCredentials(s.Req.Method, s.Req.Username, arg.GroupName, arg.Identifiers); err != nil {
		return nil, err
	}

	result := make(map[string]bool, len(arg.Identifiers))

	for _, cred := range s.Builder.Credentials {
		if cred.Provider != "vagrant" {
			return nil, errors.New("unable to authenticate non-vagrant credential: " + cred.Provider)
		}

		meta := cred.Meta.(*VagrantMeta)

		if err := meta.Valid(); err != nil {
			return nil, fmt.Errorf("validating %q credential: %s", cred.Identifier, err)
		}

		version, err := s.api.Version(meta.QueryString)
		verified := err == nil && version != ""

		if err := modelhelper.SetCredentialVerified(cred.Identifier, verified); err != nil {
			return nil, err
		}

		s.Log.Debug("authenticate %q credential: version=%q, err=%v", cred.Identifier, version, err)

		result[cred.Identifier] = verified
	}

	return result, nil
}
