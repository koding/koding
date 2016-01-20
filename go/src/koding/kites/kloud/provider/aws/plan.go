package awsprovider

import (
	"errors"
	"fmt"

	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/stackplan"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"
)

// Plan
func (s *Stack) Plan(ctx context.Context) (interface{}, error) {
	var arg kloud.PlanRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	s.Log.Debug("Fetching template for id %s", arg.StackTemplateID)
	stackTemplate, err := modelhelper.GetStackTemplate(arg.StackTemplateID)
	if err != nil {
		return nil, err
	}

	if stackTemplate.Template.Content == "" {
		return nil, errors.New("Stack template content is empty")
	}

	s.Log.Debug("Fetching credentials for id %v", stackTemplate.Credentials)

	credIDs := stackplan.FlattenValues(stackTemplate.Credentials)

	if err := s.Builder.BuildCredentials(s.Req.Method, s.Req.Username, arg.GroupName, credIDs); err != nil {
		return nil, err
	}

	s.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", s.Builder.Koding, s.Builder.Template)

	// TODO(arslan): make one single persistent connection if needed, for now
	// this is ok.
	tfKite, err := terraformer.Connect(s.Session.Kite)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	s.Log.Debug("Parsing template:\n%s", stackTemplate.Template.Content)

	if err := s.Builder.BuildTemplate(stackTemplate.Template.Content); err != nil {
		return nil, err
	}

	if err := s.Builder.Template.FillVariables("userInput_"); err != nil {
		return nil, err
	}

	var region string
	for _, cred := range s.Builder.Credentials {
		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		meta := cred.Meta.(*AwsMeta)
		if meta.Region == "" {
			return nil, fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		if err := s.SetAwsRegion(meta.Region); err != nil {
			return nil, err
		}

		region = meta.Region

		break
	}

	s.Log.Debug("Plan: stack template before injecting Koding data")
	s.Log.Debug("%v", s.Builder.Template)

	// TODO(rjeczalik): rework injectAWSData
	s.Log.Debug("Injecting AWS data")

	if _, err := s.InjectAWSData(ctx, s.Req.Username); err != nil {
		return nil, err
	}

	out, err := s.Builder.Template.JsonOutput()
	if err != nil {
		return nil, err
	}

	stackTemplate.Template.Content = out

	tfReq := &tf.TerraformRequest{
		Content:   stackTemplate.Template.Content,
		ContentID: s.Req.Username + "-" + arg.StackTemplateID,
		Variables: nil,
	}

	s.Log.Debug("Calling plan with content")
	s.Log.Debug("%+v", tfReq)

	plan, err := tfKite.Plan(tfReq)
	if err != nil {
		return nil, err
	}

	machines, err := stackplan.MachinesFromPlan(plan)
	if err != nil {
		return nil, err
	}
	machines.AppendRegion(region)

	s.Log.Debug("Machines planned to be created: %+v", machines)

	return machines, nil
}
