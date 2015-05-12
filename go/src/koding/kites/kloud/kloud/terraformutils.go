package kloud

import (
	"crypto/sha1"
	"encoding/json"
	"errors"
	"fmt"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/userdata"
	"strings"
	"sync"
	"time"

	"golang.org/x/net/context"

	"github.com/fatih/structs"
	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite/protocol"
	"github.com/mitchellh/mapstructure"
	"github.com/nu7hatch/gouuid"
)

type TerraformMachine struct {
	Provider    string            `json:"provider"`
	Label       string            `json:"label"`
	Region      string            `json:"region"`
	QueryString string            `json:"queryString,omitempty"`
	Attributes  map[string]string `json:"attributes"`
}

type Machines struct {
	Machines []TerraformMachine `json:"machines"`
}

type buildData struct {
	Template string
	Region   string
	KiteIds  map[string]string
}

func (m *Machines) AppendRegion(region string) {
	for i, machine := range m.Machines {
		machine.Region = region
		m.Machines[i] = machine
	}
}

func (m *Machines) AppendQueryString(queryStrings map[string]string) {
	for i, machine := range m.Machines {
		queryString := queryStrings[machine.Label]
		machine.QueryString = protocol.Kite{ID: queryString}.String()
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

	if err := json.Unmarshal([]byte(hclContent), &data); err != nil {
		return "", err
	}

	if data.Provider.Aws.Region == "" {
		return "", fmt.Errorf("HCL content doesn't contain region information: %s", hclContent)
	}

	return data.Provider.Aws.Region, nil
}

func injectKodingData(ctx context.Context, hclContent, username string, creds *terraformCredentials) (*buildData, error) {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return nil, errors.New("session context is not passed")
	}

	var awsOutput *AwsBootstrapOutput
	for _, cred := range creds.Creds {
		if cred.Provider != "aws" {
			continue
		}

		if err := mapstructure.Decode(cred.Data, &awsOutput); err != nil {
			return nil, err
		}
	}

	if structs.HasZero(awsOutput) {
		return nil, fmt.Errorf("Bootstrap data is incomplete: %v", awsOutput)
	}

	var data struct {
		Resource struct {
			Aws_Instance map[string]map[string]interface{} `json:"aws_instance"`
		} `json:"resource"`
		Provider struct {
			Aws struct {
				Region    string `json:"region"`
				AccessKey string `json:"access_key"`
				SecretKey string `json:"secret_key"`
			} `json:"aws"`
		} `json:"provider"`
		Variable map[string]map[string]interface{} `json:"variable,omitempty"`
	}

	if err := json.Unmarshal([]byte(hclContent), &data); err != nil {
		return nil, err
	}

	if len(data.Resource.Aws_Instance) == 0 {
		return nil, fmt.Errorf("instance is empty: %v", data.Resource.Aws_Instance)
	}

	kiteIds := make(map[string]string)

	for resourceName, instance := range data.Resource.Aws_Instance {
		// create a new kite id for every new aws resource
		kiteUUID, err := uuid.NewV4()
		if err != nil {
			return nil, err
		}

		kiteId := kiteUUID.String()

		userdata, err := sess.Userdata.Create(&userdata.CloudInitConfig{
			Username: username,
			Groups:   []string{"sudo"},
			Hostname: username, // no typo here. hostname = username
			KiteId:   kiteId,
		})
		if err != nil {
			return nil, err
		}

		kiteIds[resourceName] = kiteId
		instance["user_data"] = string(userdata)
		instance["key_name"] = awsOutput.KeyPair

		// only ovveride if the user doesn't provider it's own subnet_id
		if instance["subnet_id"] == nil {
			instance["subnet_id"] = awsOutput.Subnet
			instance["security_groups"] = []string{awsOutput.SG}
		}

		data.Resource.Aws_Instance[resourceName] = instance
	}

	out, err := json.MarshalIndent(data, "", "  ")
	if err != nil {
		return nil, err
	}

	b := &buildData{
		Template: string(out),
		KiteIds:  kiteIds,
		Region:   data.Provider.Aws.Region,
	}

	return b, nil
}

func varsFromCredentials(creds *terraformCredentials) map[string]string {
	vars := make(map[string]string, 0)
	for _, cred := range creds.Creds {
		for k, v := range cred.Data {
			vars[k] = v
		}
	}
	return vars
}

func sha1sum(s string) string {
	return fmt.Sprintf("%x", sha1.Sum([]byte(s)))
}

func checkKlients(ctx context.Context, kiteIds map[string]string) error {
	sess, ok := session.FromContext(ctx)
	if !ok {
		return errors.New("session context is not passed")
	}

	var wg sync.WaitGroup
	var mu sync.Mutex // protects multierror
	var multiErrors error

	for l, k := range kiteIds {
		wg.Add(1)
		go func(label, kiteId string) {
			defer wg.Done()

			queryString := protocol.Kite{ID: kiteId}.String()
			klientRef, err := klient.NewWithTimeout(sess.Kite, queryString, time.Minute*5)
			if err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors,
					fmt.Errorf("Couldn't connect to '%s:%s'", label, kiteId))
				mu.Unlock()
				return
			}
			defer klientRef.Close()

			if err := klientRef.Ping(); err != nil {
				mu.Lock()
				multiErrors = multierror.Append(multiErrors,
					fmt.Errorf("Couldn't send ping to '%s:%s'", label, kiteId))
				mu.Unlock()
			}
		}(l, k)
	}

	wg.Wait()

	return multiErrors
}
