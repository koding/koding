package kloud

import (
	"errors"
	"fmt"
	"koding/db/mongodb"
	"koding/kites/kloud/contexthelper/session"
	"strings"

	"golang.org/x/net/context"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
)

type PlanMachine struct {
	Provider   string            `json:"provider"`
	Attributes map[string]string `json:"attributes"`
}

type PlanOutput struct {
	Machines []PlanMachine `json:"machines"`
}

func (k *Kloud) Plan(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args struct {
		// Terraform template file
		TerraformContext string

		// Credentials contains provider to jCredential collection ids
		Credentials map[string]string
	}

	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.TerraformContext == "" {
		return nil, NewError(ErrTerraformContextIsMissing)
	}

	if len(args.Credentials) == 0 {
		return nil, errors.New("credential ids are not passed")
	}

	if k.terraformerKite == nil {
		return nil, errors.New("terraformer kite is not initialized")
	}

	ctx := k.ContextCreator(context.Background())
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	creds, err := fetchCredentials(sess.DB, args.Credentials)
	if err != nil {
		return nil, err
	}

	// TODO(arslan): fetch the credentials via args.Credentials
	// args.TerraformContext = appendVariables(args.TerraformContext, map[string]string{
	// 	"access_key": "AKIAJTDKW5IFUUIWVNAA",
	// 	"secret_key": "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",
	// })
	// fmt.Printf("args.TerraformContext = %+v\n", args.TerraformContext)

	args.TerraformContext = appendVariables(args.TerraformContext, creds)

	plan, err := k.terraformerKite.Plan(args.TerraformContext)
	if err != nil {
		return nil, err
	}

	return machineFromPlan(plan)
}

// appendVariables appends the given key/value credentials to the hclFile (terraform) file
func appendVariables(hclFile string, vars map[string]string) string {
	// TODO: use hcl encoder, this is just for testing
	for k, v := range vars {
		hclFile += "\n"
		varTemplate := `
variable "%s" {
	default = "%s"
}`
		hclFile += fmt.Sprintf(varTemplate, k, v)
	}

	return hclFile
}

func fetchCredentials(db *mongodb.MongoDB, ids map[string]string) (map[string]string, error) {
	return nil, nil
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

			// providerResource is in the form of "aws_instance.foo"
			splitted := strings.Split(providerResource, "_")
			if len(splitted) == 0 {
				return nil, fmt.Errorf("provider resource is unknown: %v", splitted)
			}

			out.Machines = append(out.Machines, PlanMachine{
				Provider:   splitted[0],
				Attributes: attrs,
			})
		}
	}

	return out, nil
}
