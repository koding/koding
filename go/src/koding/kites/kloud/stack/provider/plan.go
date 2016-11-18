package provider

import (
	"koding/kites/kloud/stack"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"
)

func (bs *BaseStack) HandlePlan(ctx context.Context) (interface{}, error) {
	arg, ok := ctx.Value(stack.PlanRequestKey).(*stack.PlanRequest)
	if !ok {
		arg = &stack.PlanRequest{}

		if err := bs.Req.Args.One().Unmarshal(arg); err != nil {
			return nil, err
		}
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	bs.Arg = arg

	bs.Log.Debug("Fetching template for id %s", arg.StackTemplateID)

	if err := bs.Builder.BuildStackTemplate(arg.StackTemplateID); err != nil {
		return nil, err
	}

	bs.Log.Debug("Fetching credentials for id %v", bs.Builder.StackTemplate.Credentials)

	credIDs := FlattenValues(bs.Builder.StackTemplate.Credentials)

	if err := bs.Builder.BuildCredentials(bs.Req.Method, bs.Req.Username, arg.GroupName, credIDs); err != nil {
		return nil, err
	}

	bs.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", bs.Builder.Koding, bs.Builder.Template)

	contentID := bs.Req.Username + "-" + arg.StackTemplateID

	bs.Log.Debug("Parsing template (%s):\n%s", contentID, bs.Builder.StackTemplate.Template.Content)

	if err := bs.Builder.BuildTemplate(bs.Builder.StackTemplate.Template.Content, contentID); err != nil {
		return nil, err
	}

	if cred, err := bs.Builder.CredentialByProvider(bs.Provider.Name); err == nil {
		if _, err := bs.stack.ApplyTemplate(cred); err != nil {
			return nil, err
		}
	} else {
		bs.Log.Debug("no credentials found for %q: %s", bs.Provider.Name, err)

		if err := bs.Builder.Template.FillVariables(bs.Provider.Name + "_"); err != nil {
			return nil, err
		}
	}

	// Plan request is made right away the template is saved, it may
	// not have all the credentials provided yet. We set them all to
	// to dummy values to make the template pass terraform parsing.
	if err := bs.Builder.Template.FillVariables("userInput_"); err != nil {
		return nil, err
	}

	machines, err := bs.plan()
	if err != nil {
		return nil, err
	}

	bs.Log.Debug("Machines planned to be created: %+v", machines)

	return &stack.PlanResponse{
		Machines: machines.Slice(),
	}, nil
}

func (bs *BaseStack) Plan() (stack.Machines, error) {
	out, err := bs.Builder.Template.JsonOutput()
	if err != nil {
		return nil, err
	}

	tfKite, err := terraformer.Connect(bs.Session.Terraformer)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	tfReq := &tf.TerraformRequest{
		Content:   out,
		ContentID: bs.Req.Username + "-" + bs.Arg.(*stack.PlanRequest).StackTemplateID,
		TraceID:   bs.TraceID,
	}

	bs.Log.Debug("Calling plan with content: %+v", tfReq)

	plan, err := tfKite.Plan(tfReq)
	if err != nil {
		return nil, err
	}

	return bs.Planner.MachinesFromPlan(plan)
}
