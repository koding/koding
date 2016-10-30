package provider

import (
	"fmt"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"
)

func (bs *BaseStack) HandleBootstrap(ctx context.Context) (interface{}, error) {
	arg, ok := ctx.Value(stack.BootstrapRequestKey).(*stack.BootstrapRequest)
	if !ok {
		arg = &stack.BootstrapRequest{}

		if err := bs.Req.Args.One().Unmarshal(arg); err != nil {
			return nil, err
		}
	}

	if err := arg.Valid(); err != nil {
		return nil, err
	}

	bs.Arg = arg

	return bs.bootstrap(arg)
}

func (bs *BaseStack) bootstrap(arg *stack.BootstrapRequest) (interface{}, error) {
	if arg.Destroy {
		bs.Log.Debug("Bootstrap destroy is called")
	} else {
		bs.Log.Debug("Bootstrap apply is called")
	}

	if err := bs.Builder.BuildCredentials(bs.Req.Method, bs.Req.Username, arg.GroupName, arg.Identifiers); err != nil {
		return nil, err
	}

	bs.Log.Debug("Connecting to terraformer kite")

	tfKite, err := terraformer.Connect(bs.Session.Terraformer)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	bs.Log.Debug("Iterating over credentials")

	var updatedCreds []*stack.Credential
	for _, cred := range bs.Builder.Credentials {
		if cred.Provider != bs.Planner.Provider {
			continue
		}

		templates, err := bs.stack.BootstrapTemplates(cred)
		if err != nil {
			return nil, err
		}

		destroyUniq := make(map[string]interface{}) // protects from double-destroy
		for _, tmpl := range templates {
			if tmpl.Key == "" {
				tmpl.Key = bs.Planner.Provider + "-" + arg.GroupName + "-" + cred.Identifier
			}

			if arg.Destroy {
				if _, ok := destroyUniq[tmpl.Key]; !ok {
					bs.Log.Info("Destroying bootstrap resources belonging to identifier '%s'", cred.Identifier)

					_, err := tfKite.Destroy(&tf.TerraformRequest{
						ContentID: tmpl.Key,
						TraceID:   bs.TraceID,
					})
					if err != nil {
						return nil, err
					}

					cred.Bootstrap = bs.Provider.newBootstrap()
					destroyUniq[tmpl.Key] = struct{}{}
					updatedCreds = append(updatedCreds, cred)
				}
			} else {
				bs.Log.Info("Creating bootstrap resources belonging to identifier '%s'", cred.Identifier)
				bs.Log.Debug("Bootstrap template:")
				bs.Log.Debug("%s", tmpl)

				// TODO(rjeczalik): use []byte for templates to avoid allocations
				if err := bs.Builder.BuildTemplate(string(tmpl.Content), tmpl.Key); err != nil {
					return nil, err
				}

				content, err := bs.Builder.Template.JsonOutput()
				if err != nil {
					return nil, err
				}

				bs.Log.Debug("Final bootstrap template: %s", content)

				state, err := tfKite.Apply(&tf.TerraformRequest{
					Content:   content,
					ContentID: tmpl.Key,
					TraceID:   bs.TraceID,
				})
				if err != nil {
					return nil, err
				}

				bs.Log.Debug("[%s] state.RootModule().Outputs = %+v\n", cred.Identifier, state.RootModule().Outputs)

				if err := bs.Builder.Object.Decode(state.RootModule().Outputs, cred.Bootstrap); err != nil {
					return nil, err
				}

				bs.Log.Debug("[%s] resp = %+v\n", cred.Identifier, cred.Bootstrap)

				if v, ok := cred.Bootstrap.(stack.Validator); ok {
					if err := v.Valid(); err != nil {
						return nil, fmt.Errorf("invalid bootstrap metadata for %q: %s", cred.Identifier, err)
					}
				}

				updatedCreds = append(updatedCreds, cred)
			}

			bs.Log.Debug("[%s] Bootstrap response: %+v", cred.Identifier, cred.Bootstrap)
		}
	}

	if err := bs.Builder.PutCredentials(bs.Req.Username, updatedCreds...); err != nil {
		return nil, err
	}

	return true, nil
}
