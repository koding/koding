package provider

import (
	"errors"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"
)

func (bs *BaseStack) HandlePlan(ctx context.Context) (interface{}, error) {
	arg, ok := ctx.Value(stack.PlanRequestKey).(*stack.PlanRequest)
	if !ok {
		arg := &stack.PlanRequest{}

		if err := bs.Req.Args.One().Unmarshal(&arg); err != nil {
			return nil, err
		}
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	bs.Arg = &arg

	bs.Log.Debug("Fetching template for id %s", arg.StackTemplateID)
	stackTemplate, err := modelhelper.GetStackTemplate(arg.StackTemplateID)
	if err != nil {
		return nil, models.ResError(err, "jStackTemplate")
	}

	if stackTemplate.Template.Content == "" {
		return nil, errors.New("Stack template content is empty")
	}

	bs.Log.Debug("Fetching credentials for id %v", stackTemplate.Credentials)

	credIDs := FlattenValues(stackTemplate.Credentials)

	if err := bs.Builder.BuildCredentials(bs.Req.Method, bs.Req.Username, arg.GroupName, credIDs); err != nil {
		return nil, err
	}

	bs.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", bs.Builder.Koding, bs.Builder.Template)

	contentID := bs.Req.Username + "-" + arg.StackTemplateID
	bs.Log.Debug("Parsing template (%s):\n%s", contentID, stackTemplate.Template.Content)

	if err := bs.Builder.BuildTemplate(stackTemplate.Template.Content, contentID); err != nil {
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

	out, err := bs.Builder.Template.JsonOutput()
	if err != nil {
		return nil, err
	}

	tfKite, err := terraformer.Connect(bs.Session.Terraformer)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	stackTemplate.Template.Content = out

	tfReq := &tf.TerraformRequest{
		Content:   stackTemplate.Template.Content,
		ContentID: contentID,
		TraceID:   bs.TraceID,
	}

	bs.Log.Debug("Calling plan with content")
	bs.Log.Debug("%+v", tfReq)

	plan, err := tfKite.Plan(tfReq)
	if err != nil {
		return nil, err
	}

	machines, err := bs.Planner.MachinesFromPlan(plan)
	if err != nil {
		return nil, err
	}

	bs.Log.Debug("Machines planned to be created: %+v", machines)

	return &stack.PlanResponse{
		Machines: machines.Slice(),
	}, nil
}
