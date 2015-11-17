package kloud

import (
	"errors"
	"fmt"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"

	"github.com/koding/kite"
)

type TerraformPlanRequest struct {
	StackTemplateId string `json:"stackTemplateId"`

	GroupName string `json:"groupName"`
}

func (k *Kloud) Plan(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args *TerraformPlanRequest
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, err
	}

	if args.StackTemplateId == "" {
		return nil, errors.New("stackIdTemplate is not passed")
	}

	if args.GroupName == "" {
		return nil, errors.New("group name is not passed")
	}

	ctx := k.ContextCreator(context.Background())
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	k.Log.Debug("Fetching template for id %s", args.StackTemplateId)
	stackTemplate, err := modelhelper.GetStackTemplate(args.StackTemplateId)
	if err != nil {
		return nil, err
	}

	if stackTemplate.Template.Content == "" {
		return nil, errors.New("Stack template content is empty")
	}

	k.Log.Debug("Fetching credentials for id %v", stackTemplate.Credentials)
	data, err := fetchTerraformData(r.Method, r.Username, args.GroupName, sess.DB, flattenValues(stackTemplate.Credentials))
	if err != nil {
		return nil, err
	}

	// TODO(arslan): make one single persistent connection if needed, for now
	// this is ok.
	tfKite, err := terraformer.Connect(sess.Kite)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	k.Log.Debug("Parsing template:\n%s", stackTemplate.Template.Content)
	template, err := newTerraformTemplate(stackTemplate.Template.Content)
	if err != nil {
		return nil, err
	}

	if err := template.fillVariables("userInput"); err != nil {
		return nil, err
	}

	var region string
	for _, cred := range data.Creds {
		k.Log.Debug("Appending %s provider variables", cred.Provider)
		if err := template.injectCustomVariables(cred.Provider, cred.Data); err != nil {
			return nil, err
		}

		// rest is aws related
		if cred.Provider != "aws" {
			continue
		}

		region, ok = cred.Data["region"]
		if !ok {
			return nil, fmt.Errorf("region for identifer '%s' is not set", cred.Identifier)
		}

		if err := template.setAwsRegion(region); err != nil {
			return nil, err
		}
	}

	sess.Log.Debug("Plan: stack template before injecting Koding data")
	sess.Log.Debug("%v", template)
	buildData, err := injectKodingData(ctx, template, r.Username, data)
	if err != nil {
		return nil, err
	}
	stackTemplate.Template.Content = buildData.Template

	k.Log.Debug("Calling plan with content\n%s", stackTemplate.Template.Content)
	plan, err := tfKite.Plan(&tf.TerraformRequest{
		Content:   stackTemplate.Template.Content,
		ContentID: r.Username + "-" + args.StackTemplateId,
		Variables: nil,
	})
	if err != nil {
		return nil, err
	}

	machines, err := machinesFromPlan(plan)
	if err != nil {
		return nil, err
	}
	machines.AppendRegion(region)

	return machines, nil
}
