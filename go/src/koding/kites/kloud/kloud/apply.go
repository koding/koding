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

	if err := machineFromState(state); err != nil {
		return nil, err
	}

	d, err := json.MarshalIndent(state, "", " ")
	if err != nil {
		return nil, err
	}

	fmt.Printf("string(d) = %+v\n", string(d))

	return nil, errors.New("not implemented yet")
}

func machineFromState(state *terraform.State) error {
	fmt.Printf("state = %+v\n", state)

	if state.Modules == nil {
		return errors.New("state modules is empty")
	}

	for _, m := range state.Modules {
		fmt.Printf("m.Output = %+v\n", m.Outputs)
		fmt.Printf("m.Dependencis = %+v\n", m.Dependencies)
		fmt.Printf("m.Path = %+v\n", m.Path)
		fmt.Printf("m.Resources = %+v\n", m.Resources)
	}

	return nil
}
