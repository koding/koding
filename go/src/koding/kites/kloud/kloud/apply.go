package kloud

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/terraformer"

	"golang.org/x/net/context"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
)

func (k *Kloud) Apply(r *kite.Request) (interface{}, error) {
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

	if len(args.MachineIds) == 0 {
		return nil, errors.New("machine ids are not passed")
	}

	if len(args.MachineIds) != len(args.PublicKeys) {
		return nil, errors.New("machineIds and publicKeys do not match")
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

	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	args.TerraformContext = appendVariables(args.TerraformContext, creds)
	state, err := tfKite.Apply(args.TerraformContext)
	if err != nil {
		return nil, err
	}

	data, err := machinesFromState(state)
	if err != nil {
		return nil, err
	}

	if err := updateMachines(ctx, data, args.MachineIds...); err != nil {
		return nil, err
	}

	d, err := json.MarshalIndent(data, "", " ")
	if err != nil {
		return nil, err
	}

	fmt.Printf("string(d) = %+v\n", string(d))

	return nil, errors.New("not implemented yet")
}

func updateMachines(ctx context.Context, data *Machines, ids ...string) error {
	_, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	return errors.New("not implemented yet")
}

func machinesFromState(state *terraform.State) (*Machines, error) {
	fmt.Printf("state = %+v\n", state)

	if state.Modules == nil {
		return nil, errors.New("state modules is empty")
	}

	out := &Machines{
		Machines: make([]PlanMachine, 0),
	}

	attrs := make(map[string]string, 0)

	for _, m := range state.Modules {
		for resource, r := range m.Resources {
			if r.Primary == nil {
				continue
			}

			provider, label, err := parseProviderAndLabel(resource)
			if err != nil {
				return nil, err
			}

			fmt.Printf("provider = %+v\n", provider)
			fmt.Printf("label = %+v\n", label)

			for key, val := range r.Primary.Attributes {
				attrs[key] = val
			}

			out.Machines = append(out.Machines, PlanMachine{
				Provider:   provider,
				Label:      label,
				Attributes: attrs,
			})
		}
	}

	return out, nil
}
