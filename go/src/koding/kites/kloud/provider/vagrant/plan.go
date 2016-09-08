package vagrant

import (
	"errors"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan"

	"golang.org/x/net/context"
)

// Plan
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

	if err := s.Builder.BuildCredentials(s.Req.Method, s.Req.Username, arg.GroupName, credIDs); err != nil {
		return nil, err
	}

	contentID := s.Req.Username + "-" + arg.StackTemplateID

	s.Log.Debug("Fetched terraform data: koding=%+v, template=%+v", s.Builder.Koding, s.Builder.Template)
	s.Log.Debug("Parsing template (%s):\n%s", contentID, stackTemplate.Template.Content)

	if err := s.Builder.BuildTemplate(stackTemplate.Template.Content, contentID); err != nil {
		return nil, err
	}

	if err := s.Builder.Template.FillVariables("userInput_"); err != nil {
		return nil, err
	}

	s.Log.Debug("Plan: stack template before injecting Koding data")
	s.Log.Debug("%v", s.Builder.Template)

	s.Log.Debug("Injecting Vagrant data")

	if _, _, err := s.InjectVagrantData(); err != nil {
		return nil, err
	}

	s.Log.Debug("Parsing machines from template:")
	s.Log.Debug("%v", s.Builder.Template)

	machines, err := s.machinesFromTemplate(s.Builder.Template)
	if err != nil {
		return nil, errors.New("failure reading machines: " + err.Error())
	}

	s.Log.Debug("Machines planned to be created: %+v", machines)

	return &stack.PlanResponse{
		Machines: machines.Slice(),
	}, nil
}
