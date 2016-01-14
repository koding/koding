package awsprovider

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/kloud"

	"golang.org/x/net/context"

	"github.com/aws/aws-sdk-go/aws/credentials"
	"gopkg.in/mgo.v2/bson"
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

	s.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", s.Builder.Koding, s.Builder.Template)

	result := make(map[string]bool, 0)

	for _, cred := range s.Builder.Credentials {
		if cred.Provider != "aws" {
			return nil, errors.New("unable to authenticate non-aws credential: " + cred.Provider)
		}

		meta := cred.Meta.(*AwsMeta)

		if err := meta.Valid(); err != nil {
			return nil, fmt.Errorf("validating %q credential: %s", cred.Identifier, err)
		}

		opts := &amazon.ClientOptions{
			Credentials: credentials.NewStaticCredentials(meta.AccessKey, meta.SecretKey, ""),
			Region:      meta.Region,
			Log:         nil, // do not log warnings, as they're expected
		}

		_, err := amazon.NewClient(opts)
		verified := err == nil // verified says whether client was successfully authenticated

		if err := modelhelper.UpdateCredential(cred.Identifier, bson.M{
			"$set": bson.M{"verified": verified},
		}); err != nil {
			return nil, err
		}

		result[cred.Identifier] = verified
	}

	s.Log.Debug("Authenticate credentials result: %+v", result)

	return result, nil
}
