package awsprovider

import (
	"fmt"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/stack"

	"github.com/aws/aws-sdk-go/aws/credentials"
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

	s.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", s.Builder.Koding, s.Builder.Template)

	resp := make(stack.AuthenticateResponse)

	for _, cred := range s.Builder.Credentials {
		res := &stack.AuthenticateResult{}
		resp[cred.Identifier] = res

		if cred.Provider != "aws" {
			res.Message = "unable to authenticate non-aws credential: " + cred.Provider
			continue
		}

		meta := cred.Meta.(*Cred)

		if err := meta.Valid(); err != nil {
			res.Message = fmt.Sprintf("validating %q credential: %s", cred.Identifier, err)
			continue
		}

		opts := &amazon.ClientOptions{
			Credentials: credentials.NewStaticCredentials(meta.AccessKey, meta.SecretKey, ""),
			Region:      meta.Region,
			Log:         nil, // do not log warnings, as they're expected
		}

		_, err := amazon.NewClient(opts)

		if err != nil {
			res.Message = err.Error()
			continue
		}

		if err := modelhelper.SetCredentialVerified(cred.Identifier, true); err != nil {
			res.Message = err.Error()
			continue
		}

		res.Verified = true
	}

	s.Log.Debug("Authenticate credentials result: %+v", resp)

	return resp, nil
}
