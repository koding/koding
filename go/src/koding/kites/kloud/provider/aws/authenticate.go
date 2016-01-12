package awsprovider

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/stackplan"

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

	data, err := stackplan.FetchTerraformData(s.Req.Method, s.Req.Username, arg.GroupName, arg.Identifiers)
	if err != nil {
		return nil, err
	}
	s.Log.Debug("Fetched terraform data: %+v", data)

	result := make(map[string]bool, 0)

	for _, cred := range data.Creds {
		// We are going to support more providers in the future, for now only allow aws
		if cred.Provider != "aws" {
			return nil, fmt.Errorf("bootstrap is only supported for 'aws' provider. Got: '%s'", cred.Provider)
		}

		accessKey := cred.Data["access_key"]
		secretKey := cred.Data["secret_key"]
		authRegion, ok := cred.Data["region"]
		if !ok {
			return nil, fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		opts := &amazon.ClientOptions{
			Credentials: credentials.NewStaticCredentials(accessKey, secretKey, ""),
			Region:      authRegion,
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
