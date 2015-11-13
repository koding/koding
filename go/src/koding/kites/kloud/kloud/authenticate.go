package kloud

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"

	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	awssession "github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/ec2"
	"github.com/koding/kite"
)

type AuthenticateRequest struct {
	// Identifiers contains identifiers to be authenticated
	Identifiers []string `json:"identifiers"`

	GroupName string `json:"groupName"`
}

func (k *Kloud) Authenticate(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *TerraformBootstrapRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if len(args.Identifiers) == 0 {
		return nil, errors.New("identifiers are not passed")
	}

	if args.GroupName == "" {
		return nil, errors.New("group name is not passed")
	}

	ctx := k.ContextCreator(context.Background())
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	data, err := fetchTerraformData(r.Method, r.Username, args.GroupName, sess.DB, args.Identifiers)
	if err != nil {
		return nil, err
	}

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

		svc := ec2.New(awssession.New(&aws.Config{
			Credentials: credentials.NewStaticCredentials(accessKey, secretKey, ""),
			Region:      aws.String(authRegion),
		}))

		// We do request to fetch and describe all supported regions. This
		// doesn't create any resources but validates the request itself before
		// we can make a request. An error means no validation.
		verified := true
		if _, err = svc.DescribeRegions(&ec2.DescribeRegionsInput{}); err != nil {
			verified = false
		}

		if err := modelhelper.UpdateCredential(cred.Identifier, bson.M{
			"$set": bson.M{"verified": verified},
		}); err != nil {
			return nil, err
		}

		result[cred.Identifier] = verified
	}

	return result, nil
}
