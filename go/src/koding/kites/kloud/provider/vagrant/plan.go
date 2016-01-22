package vagrant

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/stackplan"

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
	s.Log.Debug("Parsing template:\n%s", stackTemplate.Template.Content)

	if err := s.Builder.BuildTemplate(stackTemplate.Template.Content); err != nil {
		return nil, err
	}

	if err := s.Builder.Template.FillVariables("userInput_"); err != nil {
		return nil, err
	}

	s.Log.Debug("Plan: stack template before injecting Koding data")
	s.Log.Debug("%v", s.Builder.Template)

	s.Log.Debug("Injecting Vagrant data")

	hostQueryString, _, err := s.InjectVagrantData(ctx, s.Req.Username)
	if err != nil {
		return nil, err
	}

	machines, err := s.machinesFromTemplate(s.Builder.Template, hostQueryString)
	if err != nil {
		return nil, err
	}

	s.Log.Debug("Machines planned to be created: %+v", machines)

	return machines, nil
}
