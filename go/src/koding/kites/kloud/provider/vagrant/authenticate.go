package vagrant

import (
	"fmt"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/stack"

	"golang.org/x/net/context"
)

// Authenticate
func (s *Stack) Authenticate(ctx context.Context) (interface{}, error) {
	var arg stack.AuthenticateRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	if err := s.Builder.BuildCredentials(s.Req.Method, s.Req.Username, arg.GroupName, arg.Identifiers); err != nil {
		return nil, err
	}

	resp := make(stack.AuthenticateResponse)

	for _, cred := range s.Builder.Credentials {
		res := &stack.AuthenticateResult{}
		resp[cred.Identifier] = res

		if cred.Provider != "vagrant" {
			res.Message = "unable to authenticate non-vagrant credential: " + cred.Provider
			continue
		}

		meta := cred.Meta.(*Cred)

		if err := meta.Valid(); err != nil {
			res.Message = fmt.Sprintf("validating %q credential: %s", cred.Identifier, err)
			continue
		}

		version, err := s.api.Version(meta.QueryString)
		s.Log.Debug("Auth response from %q: version=%q, err=%v", meta.QueryString, version, err)

		if err != nil {
			res.Message = err.Error()
			continue
		}

		if version == "" {
			res.Message = "vagrant version is empty"
			continue
		}

		if err := modelhelper.SetCredentialVerified(cred.Identifier, true); err != nil {
			res.Message = err.Error()
			continue
		}

		res.Verified = true
	}

	s.Log.Debug("authenticate response: %v", resp)

	return resp, nil
}
