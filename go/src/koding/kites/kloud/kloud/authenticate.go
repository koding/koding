package kloud

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"

	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"

	"github.com/awslabs/aws-sdk-go/aws"
	"github.com/awslabs/aws-sdk-go/service/ec2"
	"github.com/koding/kite"
)

type AuthenticateRequest struct {
	// PublicKeys contains publicKeys to be authenticated
	PublicKeys []string `json:"publicKeys"`
}

func (k *Kloud) Authenticate(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *TerraformBootstrapRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if len(args.PublicKeys) == 0 {
		return nil, errors.New("publicKeys are not passed")
	}

	ctx := k.ContextCreator(context.Background())
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	creds, err := fetchCredentials(r.Username, sess.DB, args.PublicKeys)
	if err != nil {
		return nil, err
	}

	result := make(map[string]bool, 0)

	for _, cred := range creds.Creds {
		// We are going to support more providers in the future, for now only allow aws
		if cred.Provider != "aws" {
			return nil, fmt.Errorf("bootstrap is only supported for 'aws' provider. Got: '%s'", cred.Provider)
		}

		accessKey := cred.Data["access_key"]
		secretKey := cred.Data["secret_key"]
		authRegion := cred.Data["region"]
		if authRegion == "" {
			return nil, fmt.Errorf("region for publicKey '%s' is not set", cred.PublicKey)
		}

		svc := ec2.New(&aws.Config{
			Credentials: aws.Creds(accessKey, secretKey, ""),
			Region:      authRegion,
		})

		// We do request to fetch and describe all supported regions. This
		// doesn't create any resources but validates the request itself before
		// we can make a request. An error means no validation.
		verified := true
		_, err := svc.DescribeRegions(&ec2.DescribeRegionsInput{})
		if err != nil {
			verified = false
		}

		if err := modelhelper.UpdateCredential(cred.PublicKey, bson.M{
			"$set": bson.M{"verified": verified},
		}); err != nil {
			return nil, err
		}

		result[cred.PublicKey] = verified
	}

	return result, nil
}
