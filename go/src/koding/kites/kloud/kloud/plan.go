package kloud

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/terraformer"
	"strings"

	"labix.org/v2/mgo/bson"

	"golang.org/x/net/context"

	"github.com/hashicorp/hcl"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/mitchellh/mapstructure"
)

type PlanMachine struct {
	Provider   string            `json:"provider"`
	Label      string            `json:"label"`
	Region     string            `json:"region"`
	Attributes map[string]string `json:"attributes"`
}

type PlanOutput struct {
	Machines []PlanMachine `json:"machines"`
}

type TerraformKloudRequest struct {
	MachineIds []string `json:"machineIds"`

	// Terraform template file
	TerraformContext string `json:"terraformContext"`

	// PublicKeys contains provider to publicKeys mapping
	PublicKeys map[string]string `json:"publicKeys"`
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

	var args *TerraformKloudRequest
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
	out, err := hcl.Parse(args.TerraformContext)
	if err != nil {
		return nil, err
	}

	rg := out.Get("provider", true).Get("aws", true).Get("region", true)
	if rg == nil {
		return nil, fmt.Errorf("out shouldn't produce a nil r: %v", out)
	}

	region, ok := rg.Value.(string)
	if !ok {
		return nil, fmt.Errorf("region is not of type string: %v", region)
	}

	output, err := machineFromPlan(plan)
	if err != nil {
		return nil, err
	}

	for i, machine := range output.Machines {
		machine.Region = region
		output.Machines[i] = machine
	}

	return output, nil
}

// appendVariables appends the given key/value credentials to the hclFile (terraform) file
func appendVariables(hclFile string, creds *terraformCredentials) string {
	// TODO: use hcl encoder, this is just for testing
	for _, cred := range creds.Creds {
		// we only support aws for now
		if cred.Provider != "aws" {
			continue
		}

		for k, v := range cred.Data {
			hclFile += "\n"
			varTemplate := `
variable "%s" {
	default = "%s"
}`
			hclFile += fmt.Sprintf(varTemplate, k, v)
		}
	}

	return hclFile
}

func fetchCredentials(username string, db *mongodb.MongoDB, keys map[string]string) (*terraformCredentials, error) {
	// 1- fetch jaccount from username
	account, err := modelhelper.GetAccount(username)
	if err != nil {
		return nil, err
	}

	// 2- fetch credential from publickey via args
	publicKeys := make([]string, 0)
	for _, publicKey := range keys {
		publicKeys = append(publicKeys, publicKey)
	}

	credentials, err := modelhelper.GetCredentialsFromPublicKeys(publicKeys...)
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

func machineFromPlan(plan *terraform.Plan) (*PlanOutput, error) {
	out := &PlanOutput{
		Machines: make([]PlanMachine, 0),
	}

	attrs := make(map[string]string, 0)

	if plan.Diff == nil {
		return nil, errors.New("plan diff is empty")
	}

	if plan.Diff.Modules == nil {
		return nil, errors.New("plan diff module is empty")
	}

	for _, d := range plan.Diff.Modules {
		if d.Resources == nil {
			continue
		}

		for providerResource, r := range d.Resources {
			if r.Attributes == nil {
				continue
			}

			for name, a := range r.Attributes {
				attrs[name] = a.New
			}

			// providerResource is in the form of "aws_instance.foo.bar"
			splitted := strings.Split(providerResource, "_")
			if len(splitted) < 2 {
				return nil, fmt.Errorf("provider resource is unknown: %v", splitted)
			}

			// splitted[1]: instance.foo.bar
			resourceSplitted := strings.SplitN(splitted[1], ".", 2)

			providerName := splitted[0]          // aws
			resourceLabel := resourceSplitted[1] // foo.bar

			out.Machines = append(out.Machines, PlanMachine{
				Provider:   providerName,
				Label:      resourceLabel,
				Attributes: attrs,
			})
		}
	}

	return out, nil
}
