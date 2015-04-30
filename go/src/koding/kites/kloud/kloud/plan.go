package kloud

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/terraformer"

	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"

	"github.com/koding/kite"
	"github.com/mitchellh/mapstructure"
)

type TerraformPlanRequest struct {
	// Terraform template file
	TerraformContext string `json:"terraformContext"`

	// PublicKeys contains publicKeys to be used with terraform
	PublicKeys []string `json:"publicKeys"`
}

type terraformCredentials struct {
	Creds []*terraformCredential
}

type terraformCredential struct {
	Provider string
	Data     map[string]string `mapstructure:"data"`
}

func (k *Kloud) Plan(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *TerraformPlanRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.TerraformContext == "" {
		return nil, NewError(ErrTerraformContextIsMissing)
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

	// TODO(arslan): make one single persistent connection if needed, for now
	// this is ok.
	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	args.TerraformContext = appendVariables(args.TerraformContext, creds)

	plan, err := tfKite.Plan(args.TerraformContext)
	if err != nil {
		return nil, err
	}

	// currently there is no multi provider support for terraform. Until it's
	// been released with 0.5,  we're going to retrieve it from the "provider"
	// block: https://github.com/hashicorp/terraform/pull/1281
	region, err := regionFromHCL(args.TerraformContext)
	if err != nil {
		return nil, err
	}

	machines, err := machinesFromPlan(plan)
	if err != nil {
		return nil, err
	}

	machines.AppendRegion(region)

	return machines, nil
}

func fetchCredentials(username string, db *mongodb.MongoDB, keys []string) (*terraformCredentials, error) {
	// 1- fetch jaccount from username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	// 2- fetch credential from publickey via args
	credentials, err := modelhelper.GetCredentialsFromPublicKeys(keys...)
	if err != nil {
		return nil, err
	}

	// 3- count relationship with credential id and jaccount id as user or
	// owner. Any non valid credentials will be discarded
	validKeys := make(map[string]string, 0)

	for _, cred := range credentials {
		selector := modelhelper.Selector{
			"targetId": cred.Id,
			"sourceId": account.Id,
			"as": bson.M{
				"$in": []string{"owner", "user"},
			},
		}

		count, err := modelhelper.RelationshipCount(selector)
		if err != nil {
			// we return for any not validated public key.
			return nil, fmt.Errorf("credential with publicKey '%s' is not validated", cred.PublicKey)
		}

		// does this ever happen ?
		if count == 0 {
			return nil, fmt.Errorf("credential with publicKey '%s' is not validated", cred.PublicKey)
		}

		validKeys[cred.PublicKey] = cred.Provider
	}

	// 4- fetch credentialdata with publickey
	validPublicKeys := make([]string, 0)
	for pKey := range validKeys {
		validPublicKeys = append(validPublicKeys, pKey)
	}

	credentialData, err := modelhelper.GetCredentialDatasFromPublicKeys(validPublicKeys...)
	if err != nil {
		return nil, err
	}

	// 5- return list of keys. We only support aws for now
	creds := &terraformCredentials{
		Creds: make([]*terraformCredential, 0),
	}

	for _, data := range credentialData {
		provider, ok := validKeys[data.PublicKey]
		if !ok {
			return nil, fmt.Errorf("provider is not found for key: %s", data.PublicKey)
		}
		// for now we only support aws
		if provider != "aws" {
			continue
		}

		cred := &terraformCredential{
			Provider: provider,
		}

		if err := mapstructure.Decode(data.Meta, &cred.Data); err != nil {
			return nil, err
		}
		creds.Creds = append(creds.Creds, cred)

	}
	return creds, nil
}
