package kloud

import (
	"errors"
	"fmt"
	"strings"

	"github.com/hashicorp/hcl"
	"github.com/hashicorp/terraform/terraform"
)

type TerraformMachine struct {
	Provider   string            `json:"provider"`
	Label      string            `json:"label"`
	Region     string            `json:"region"`
	Attributes map[string]string `json:"attributes"`
}

type Machines struct {
	Machines []TerraformMachine `json:"machines"`
}

func (m *Machines) AppendRegion(region string) {
	for i, machine := range m.Machines {
		machine.Region = region
		m.Machines[i] = machine
	}
}

// WithLabel returns the machine with the associated label
func (m *Machines) WithLabel(label string) (TerraformMachine, error) {
	for _, machine := range m.Machines {
		if machine.Label == label {
			return machine, nil
		}
	}

	return TerraformMachine{}, fmt.Errorf("couldn't find machine with label '%s", label)
}

func machinesFromState(state *terraform.State) (*Machines, error) {
	if state.Modules == nil {
		return nil, errors.New("state modules is empty")
	}

	out := &Machines{
		Machines: make([]TerraformMachine, 0),
	}

	attrs := make(map[string]string, 0)

	for _, m := range state.Modules {
		for resource, r := range m.Resources {
			if r.Primary == nil {
				continue
			}

			provider, label, err := parseProviderAndLabel(resource)
			if err != nil {
				return nil, err
			}

			for key, val := range r.Primary.Attributes {
				attrs[key] = val
			}

			out.Machines = append(out.Machines, TerraformMachine{
				Provider:   provider,
				Label:      label,
				Attributes: attrs,
			})
		}
	}

	return out, nil
}

func machinesFromPlan(plan *terraform.Plan) (*Machines, error) {
	if plan.Diff == nil {
		return nil, errors.New("plan diff is empty")
	}

	if plan.Diff.Modules == nil {
		return nil, errors.New("plan diff module is empty")
	}

	out := &Machines{
		Machines: make([]TerraformMachine, 0),
	}

	attrs := make(map[string]string, 0)

	for _, d := range plan.Diff.Modules {
		if d.Resources == nil {
			continue
		}

		for providerResource, r := range d.Resources {
			if r.Attributes == nil {
				continue
			}

			for name, a := range r.Attributes {
				attrs[name] = a.New
			}

			provider, label, err := parseProviderAndLabel(providerResource)
			if err != nil {
				return nil, err
			}

			out.Machines = append(out.Machines, TerraformMachine{
				Provider:   provider,
				Label:      label,
				Attributes: attrs,
			})
		}
	}

	return out, nil
}

func parseProviderAndLabel(resource string) (string, string, error) {
	// resource is in the form of "aws_instance.foo.bar"
	splitted := strings.Split(resource, "_")
	if len(splitted) < 2 {
		return "", "", fmt.Errorf("provider resource is unknown: %v", splitted)
	}

	// splitted[1]: instance.foo.bar
	resourceSplitted := strings.SplitN(splitted[1], ".", 2)

	provider := splitted[0]      // aws
	label := resourceSplitted[1] // foo.bar

	return provider, label, nil
}

func regionFromHCL(hclContent string) (string, error) {
	var data struct {
		Provider struct {
			Aws struct {
				Region string
			}
		}
	}

	if err := hcl.Decode(&data, hclContent); err != nil {
		return "", err
	}

	if data.Provider.Aws.Region == "" {
		return "", fmt.Errorf("HCL content doesn't contain region information: %s", hclContent)
	}

	return data.Provider.Aws.Region, nil
}

// appendVariables appends the given key/value credentials to the hclFile (terraform) file
func appendVariables(hclFile string, creds *terraformCredentials) string {
	// TODO: use hcl encoder, this is just for testing
	for _, cred := range creds.Creds {
		// we only support aws for now
		if cred.Provider != "aws" {
			continue
		}

		for k, v := range cred.Data {
			hclFile += "\n"
			varTemplate := `
variable "%s" {
	default = "%s"
}`
			hclFile += fmt.Sprintf(varTemplate, k, v)
		}
	}

	return hclFile
}
