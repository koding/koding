package kloud

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/terraformer"

	"golang.org/x/net/context"

	"github.com/koding/kite"
)

func (k *Kloud) Apply(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *PlanRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.TerraformContext == "" {
		return nil, NewError(ErrTerraformContextIsMissing)
	}

	if len(args.PublicKeys) == 0 {
		return nil, errors.New("credential ids are not passed")
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

	fmt.Printf("state = %+v\n", state)

	// out, err := machineFromPlan(plan)
	// if err != nil {
	// 	return nil, err
	// }

	d, err := json.MarshalIndent(state, "", " ")
	if err != nil {
		return nil, err
	}

	fmt.Printf(string(d))

	return nil, errors.New("not implemented yet")
}
