package azure

import (
	"errors"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"
)

func (s *Stack) Plan(ctx context.Context) (interface{}, error) {
	var arg stack.PlanRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	s.Log.Debug("Fetching template for id %s", arg.StackTemplateID)
	stackTemplate, err := modelhelper.GetStackTemplate(arg.StackTemplateID)
	if err != nil {
		return nil, stackplan.ResError(err, "jStackTemplate")
	}

	if stackTemplate.Template.Content == "" {
		return nil, errors.New("Stack template content is empty")
	}

	s.Log.Debug("Fetching credentials for id %v", stackTemplate.Credentials)

	credIDs := stackplan.FlattenValues(stackTemplate.Credentials)

	if err := s.BuildCredentials(arg.GroupName, credIDs); err != nil {
		return nil, err
	}

	s.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", s.Builder.Koding, s.Builder.Template)

	tfKite, err := terraformer.Connect(s.Session.Terraformer)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	contentID := s.Req.Username + "-" + arg.StackTemplateID
	s.Log.Debug("Parsing template (%s):\n%s", contentID, stackTemplate.Template.Content)

	if err := s.Builder.BuildTemplate(stackTemplate.Template.Content, contentID); err != nil {
		return nil, err
	}

	s.Log.Debug("Plan: stack template before injecting Koding data")
	s.Log.Debug("%v", s.Builder.Template)

	s.Log.Debug("Injecting AWS data")

	if _, err := s.InjectAzureData(); err != nil {
		return nil, err
	}

	if err := s.Builder.Template.FillVariables("userInput_"); err != nil {
		return nil, err
	}

	if s.Cred() == nil {
		if err := s.Builder.Template.FillVariables("azure_"); err != nil {
			return nil, err
		}
	}

	out, err := s.Builder.Template.JsonOutput()
	if err != nil {
		return nil, err
	}

	stackTemplate.Template.Content = out

	tfReq := &tf.TerraformRequest{
		Content:   stackTemplate.Template.Content,
		ContentID: contentID,
		TraceID:   s.TraceID,
	}

	s.Log.Debug("Calling plan with content")
	s.Log.Debug("%+v", tfReq)

	plan, err := tfKite.Plan(tfReq)
	if err != nil {
		return nil, err
	}

	machines, err := s.p.MachinesFromPlan(plan)
	if err != nil {
		return nil, err
	}

	s.Log.Debug("Machines planned to be created: %+v", machines)

	return &stack.PlanResponse{
		Machines: machines.Slice(),
	}, nil
}
