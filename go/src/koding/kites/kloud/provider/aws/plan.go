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
	data, err := stackplan.FetchTerraformData(s.Req.Method, s.Req.Username, arg.GroupName, stackplan.FlattenValues(stackTemplate.Credentials))
	if err != nil {
		return nil, err
	}
	s.Log.Debug("Fetched terraform data: %+v", data)

	// TODO(arslan): make one single persistent connection if needed, for now
	// this is ok.
	tfKite, err := terraformer.Connect(s.Session.Kite)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	s.Log.Debug("Parsing template:\n%s", stackTemplate.Template.Content)
	template, err := stackplan.ParseTemplate(stackTemplate.Template.Content)
	if err != nil {
		return nil, err
	}

	if err := template.FillVariables("userInput"); err != nil {
		return nil, err
	}

	var region string
	for _, cred := range data.Creds {
		s.Log.Debug("Appending %s provider variables", cred.Provider)
		if err := template.InjectCustomVariables(cred.Provider, cred.Data); err != nil {
			return nil, err
		}

		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		var ok bool
		region, ok = cred.Data["region"]
		if !ok {
			return nil, fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		if err := template.SetAwsRegion(region); err != nil {
			return nil, err
		}
	}

	s.Log.Debug("Plan: stack template before injecting Koding data")
	s.Log.Debug("%v", template)

	s.Log.Debug("Injecting Koding data")
	// inject koding variables, in the form of koding_user_foo,
	// koding_group_name, etc..
	if err := template.InjectKodingVariables(data.KodingData); err != nil {
		return nil, err
	}

	// TODO(rjeczalik): rework injectAWSData
	s.Log.Debug("Injecting AWS data")
	_, err = stackplan.InjectAWSData(ctx, template, s.Req.Username, data)
	if err != nil {
		return nil, err
	}
	out, err := template.JsonOutput()
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
