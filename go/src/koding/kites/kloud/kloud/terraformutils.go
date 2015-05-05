package kloud

import (
	"crypto/sha1"
	"encoding/json"
	"errors"
	"fmt"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/klient"
	"koding/kites/kloud/userdata"
	"strings"
	"sync"
	"time"

	"golang.org/x/net/context"

	"github.com/hashicorp/go-multierror"
	"github.com/hashicorp/hcl"
	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite/protocol"
	"github.com/mitchellh/goamz/aws"
	"github.com/mitchellh/goamz/ec2"
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

	if err := hcl.Decode(&data, hclContent); err != nil {
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

	keys, ok := publickeys.FromContext(ctx)
	if !ok {
		return nil, errors.New("public keys are not available")
	}

	// for now we only support "aws", the logic below should be refactored once
	// we support multiple providers
	var accessKey, secretKey string
	for _, c := range creds.Creds {
		if c.Provider != "aws" {
			continue
		}

		accessKey = c.Data["access_key"]
		secretKey = c.Data["secret_key"]
	}

	region, err := regionFromHCL(hclContent)
	if err != nil {
		return nil, err
	}

	// inject our own public/private keys into the machine
	amazonClient, err := amazon.New(
		map[string]interface{}{
			"key_pair":   keys.KeyName,
			"publicKey":  keys.PublicKey,
			"privateKey": keys.PrivateKey,
		},
		ec2.New(
			aws.Auth{AccessKey: accessKey, SecretKey: secretKey},
			aws.Regions[region],
		))
	if err != nil {
		return nil, fmt.Errorf("kloud aws client err: %s", err)
	}

	subnets, err := amazonClient.ListSubnets()
	if err != nil {
		return nil, err
	}

	if len(subnets.Subnets) == 0 {
		return nil, errors.New("no subnets are available")
	}

	var subnetId string
	var vpcId string
	for _, subnet := range subnets.Subnets {
		if subnet.AvailableIpAddressCount == 0 {
			continue
		}

		subnetId = subnet.SubnetId
		vpcId = subnet.VpcId
	}

	if subnetId == "" {
		return nil, errors.New("subnetId is empty")
	}

	var groupName = "Koding-Kloud-SG"
	sess.Log.Debug("Fetching or creating SG: %s, %s", groupName, vpcId)
	group, err := amazonClient.CreateOrGetSecurityGroup(groupName, vpcId)
	if err != nil {
		return nil, err
	}

	sess.Log.Debug("first group = %+v\n", group)
	sess.Log.Debug("vpcId = %+v\n", vpcId)
	sess.Log.Debug("subnetId = %+v\n", subnetId)

	// this will either create the "kloud-deployment" key or it will just
	// return with a nil error (means success)
	if _, err = amazonClient.DeployKey(); err != nil {
		return nil, err
	}

	var data struct {
		Resource struct {
			Aws_Instance map[string]map[string]interface{} `json:"aws_instance"`
		} `json:"resource"`
		Provider map[string]map[string]interface{} `json:"provider"`
		Variable map[string]map[string]interface{} `json:"variable"`
	}

	if err := hcl.Decode(&data, hclContent); err != nil {
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
		instance["key_name"] = keys.KeyName
		instance["security_groups"] = []string{group.Id}

		// user has provided a custom subnet id, if this is the case, fetch the
		// securitygroup from it.
		if instance["subnet_id"] != "" {
			subnetId := instance["subnet_id"]
			var subnet ec2.Subnet
			found := false
			for _, s := range subnets.Subnets {
				if s.SubnetId == subnetId {
					found = true
					subnet = s
				}
			}

			if !found {
				return nil, fmt.Errorf("no subnet with id '%s' found", subnetId)
			}

			group, err := amazonClient.CreateOrGetSecurityGroup(groupName, subnet.VpcId)
			if err != nil {
				return nil, err
			}

			sess.Log.Debug("second group = %+v\n", group)
			instance["security_groups"] = []string{group.Id}
		} else {
			instance["subnet_id"] = subnetId
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
		Region:   region,
	}

	return b, nil
}

// appendVariables appends the given key/value credentials to the hclFile (terraform) file
func appendVariables(hclFile string, creds *terraformCredentials) (string, error) {

	found := false
	for _, cred := range creds.Creds {
		// we only support aws for now
		if cred.Provider != "aws" {
			continue
		}

		found = true
		for k, v := range cred.Data {
			hclFile += "\n"
			varTemplate := `
variable "%s" {
	default = "%s"
}`
			hclFile += fmt.Sprintf(varTemplate, k, v)
		}
	}

	if !found {
		return "", fmt.Errorf("no creds found for: %v", creds)
	}

	return hclFile, nil
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
