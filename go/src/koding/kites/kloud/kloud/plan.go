package kloud

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"

	"github.com/koding/kite"
	"github.com/mitchellh/mapstructure"
)

type TerraformPlanRequest struct {
	StackTemplateId string `json:"stackTemplateId"`
}

type terraformCredentials struct {
	Creds []*terraformCredential
}

type terraformCredential struct {
	Provider  string
	PublicKey string
	Data      map[string]string `mapstructure:"data"`
}

// region returns the region from the credential data
func (t *terraformCredential) region() (string, error) {
	// for now we support only aws
	if t.Provider != "aws" {
		return "", fmt.Errorf("provider '%s' is not supported", t.Provider)
	}

	region := t.Data["region"]
	if region == "" {
		return "", fmt.Errorf("region for publicKey '%s' is not set", t.PublicKey)
	}

	return region, nil
}

// appendAWSVariable appends the credentials aws data to the given template and
// returns it back.
func (t *terraformCredential) appendAWSVariable(template string) (string, error) {
	var data struct {
		Output   map[string]map[string]interface{} `json:"output,omitempty"`
		Resource map[string]map[string]interface{} `json:"resource,omitempty"`
		Provider struct {
			Aws struct {
				Region    string `json:"region"`
				AccessKey string `json:"access_key"`
				SecretKey string `json:"secret_key"`
			} `json:"aws"`
		} `json:"provider"`
		Variable map[string]map[string]interface{} `json:"variable,omitempty"`
	}

	if err := json.Unmarshal([]byte(template), &data); err != nil {
		return "", err
	}

	credRegion := t.Data["region"]
	if credRegion == "" {
		return "", fmt.Errorf("region for publicKey '%s' is not set", t.PublicKey)
	}

	// if region is not added, add it via credRegion
	region := data.Provider.Aws.Region
	if region == "" {
		data.Provider.Aws.Region = credRegion
	} else if !isVariable(region) && region != credRegion {
		// compare with the provider block's region. Don't allow if they are
		// different.
		return "", fmt.Errorf("region in the provider block doesn't match the region in credential data. Provider block: '%s'. Credential data: '%s'", region, credRegion)
	}

	if data.Variable == nil {
		data.Variable = make(map[string]map[string]interface{})
	}

	data.Variable["access_key"] = map[string]interface{}{
		"default": t.Data["access_key"],
	}

	data.Variable["secret_key"] = map[string]interface{}{
		"default": t.Data["secret_key"],
	}

	data.Variable["region"] = map[string]interface{}{
		"default": credRegion,
	}

	out, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return "", err
	}

	return string(out), nil
}

func (k *Kloud) Plan(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *TerraformPlanRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.StackTemplateId == "" {
		return nil, errors.New("stackIdTemplate is not passed")
	}

	ctx := k.ContextCreator(context.Background())
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	stackTemplate, err := modelhelper.GetStackTemplate(args.StackTemplateId)
	if err != nil {
		return nil, err
	}

	creds, err := fetchCredentials(r.Username, sess.DB, stackTemplate.Credentials)
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

	var region string
	for _, cred := range creds.Creds {
		region, err = cred.region()
		if err != nil {
			return nil, err
		}

		stackTemplate.Template.Content, err = cred.appendAWSVariable(stackTemplate.Template.Content)
		if err != nil {
			return nil, err
		}
	}

	plan, err := tfKite.Plan(&tf.TerraformRequest{
		Content:   stackTemplate.Template.Content,
		ContentID: r.Username + "-" + args.StackTemplateId,
		Variables: nil,
	})
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
			Provider:  provider,
			PublicKey: data.PublicKey,
		}

		if err := mapstructure.Decode(data.Meta, &cred.Data); err != nil {
			return nil, err
		}
		creds.Creds = append(creds.Creds, cred)

	}
	return creds, nil
}
