package azure

import (
	"bytes"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"text/template"

	"github.com/Azure/azure-sdk-for-go/management"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/userdata"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1470666525 -pkg azure -o bootstrap.json.tmpl.go bootstrap.json.tmpl
//go:generate go fmt bootstrap.json.tmpl.go

var tmpl = template.Must(template.New("").Parse(mustAsset("bootstrap.json.tmpl")))

type BootstrapConfig struct {
	TeamSlug           string
	HostedServiceName  string
	StorageServiceName string
	SecurityGroupName  string
	VirtualNetworkName string
	Rule               bool
}

type Endpoint struct {
	Name        string `hcl:"name"`
	Protocol    string `hcl:"protocol"`
	PublicPort  int    `hcl:"public_port"`
	PrivatePort int    `hcl:"private_port"`
}

var vmKlient = &Endpoint{
	Name:        "klient",
	Protocol:    "tcp",
	PublicPort:  56789,
	PrivatePort: 56789,
}

var vmSSH = &Endpoint{
	Name:        "ssh",
	Protocol:    "tcp",
	PublicPort:  22,
	PrivatePort: 22,
}

// Stack implements the kloud.StackProvider interface.
type Stack struct {
	*provider.BaseStack
}

var (
	_ provider.Stack = (*Stack)(nil) // public API
	_ stack.Stacker  = (*Stack)(nil) // internal API
)

func (s *Stack) Cred() *Cred {
	return s.BaseStack.Credential.(*Cred)
}

func (s *Stack) Bootstrap() *Bootstrap {
	return s.BaseStack.Bootstrap.(*Bootstrap)
}

func (s *Stack) BootstrapArg() *stack.BootstrapRequest {
	return s.BaseStack.Arg.(*stack.BootstrapRequest)
}

func (s *Stack) VerifyCredential(c *stack.Credential) error {
	cred := c.Credential.(*Cred)

	if err := cred.Valid(); err != nil {
		return err
	}

	client, err := management.ClientFromPublishSettingsData(cred.PublishSettings, cred.SubscriptionID)
	if err != nil {
		return err
	}

	err = client.WaitForOperation("invalid", nil)
	if err != nil && !strings.Contains(err.Error(), "The operation request ID was not found") {
		return err
	}

	return nil
}

func (s *Stack) BootstrapTemplates(c *stack.Credential) ([]*stack.Template, error) {
	boot := c.Bootstrap.(*Bootstrap)

	cfg := &BootstrapConfig{
		TeamSlug:           s.BootstrapArg().GroupName,
		HostedServiceName:  "koding-hs-" + c.Identifier,
		StorageServiceName: strings.ToLower("kodings" + c.Identifier),
		SecurityGroupName:  "koding-sg-" + c.Identifier,
		VirtualNetworkName: "koding-vn-" + c.Identifier,
		Rule:               false,
	}

	// If boostrap has already storage service configured, do not create it.
	if boot.StorageServiceID != "" {
		cfg.StorageServiceName = ""
	}

	bootstrapTmpl, err := newBootstrapTmpl(cfg)
	if err != nil {
		return nil, err
	}

	// Azure requires two-step bootstrapping, as creating security
	// group rule is not possible within the same template
	// the group is being created.
	cfg.Rule = true

	ruleTmpl, err := newBootstrapTmpl(cfg)
	if err != nil {
		return nil, err
	}

	return []*stack.Template{
		{Content: string(bootstrapTmpl)},
		{Content: string(ruleTmpl)},
	}, nil
}

func (s *Stack) ApplyTemplate(c *stack.Credential) (*stack.Template, error) {
	t := s.Builder.Template

	cred := c.Credential.(*Cred)
	boot := c.Bootstrap.(*Bootstrap)

	var res struct {
		AzureInstance map[string]map[string]interface{} `hcl:"azure_instance"`
	}

	if err := t.DecodeResource(&res); err != nil {
		return nil, err
	}

	if len(res.AzureInstance) == 0 {
		return nil, errors.New("no Azure instance found")
	}

	for name, vm := range res.AzureInstance {
		// Set defaults from bootstrapped metadata.

		if s, ok := vm["hosted_service_name"]; !ok || s == "" {
			vm["hosted_service_name"] = boot.HostedServiceID
		}

		if s, ok := vm["storage_service_name"]; !ok || s == "" {
			vm["storage_service_name"] = boot.StorageServiceID
		}

		if s, ok := vm["security_group"]; !ok || s == "" {
			vm["security_group"] = boot.SecurityGroupID
		}

		if s, ok := vm["virtual_network"]; !ok || s == "" {
			vm["virtual_network"] = boot.VirtualNetworkID
		}

		if s, ok := vm["subnet"]; !ok || s == "" {
			vm["subnet"] = boot.SubnetName
		}

		if s, ok := vm["location"]; !ok || s == "" {
			vm["location"] = cred.Location
		}

		if u, ok := vm["username"]; !ok || u == "" {
			vm["username"] = s.Req.Username
		}

		endpoints, ok := vm["endpoint"].([]interface{})
		if !ok {
			endpoints = make([]interface{}, 0, 2)
		}

		// Ensure klient port is exposed.
		if i := endpointsIndex(endpoints, vmKlient.Name); i != -1 {
			endpoints[i] = vmKlient
		} else {
			endpoints = append(endpoints, vmKlient)
		}

		// Look for SSH endpoint and add a default one
		// if it was not specified.
		if i := endpointsIndex(endpoints, vmSSH.Name); i == -1 {
			endpoints = append(endpoints, vmSSH)
		}

		vm["endpoint"] = endpoints

		// means there will be several instances, we need to create a userdata
		// with count interpolation, because each machine must have an unique
		// kite id.
		count := 1
		if n, ok := vm["count"].(int); ok && n > 1 {
			count = n
		}

		var labels []string
		if count > 1 {
			for i := 0; i < count; i++ {
				labels = append(labels, fmt.Sprintf("%s.%d", name, i))
			}
		} else {
			labels = append(labels, name)
		}

		kiteKeyName := fmt.Sprintf("kitekeys_%s", name)

		// this part will be the same for all machines
		userCfg := &userdata.CloudInitConfig{
			Username: s.Req.Username,
			Groups:   []string{"sudo"},
			Hostname: s.Req.Username,
			KiteKey:  fmt.Sprintf("${lookup(var.%s, count.index)}", kiteKeyName),
		}

		s.Builder.InterpolateField(vm, name, "custom_data")

		if b, ok := vm["debug"].(bool); ok && b {
			s.Debug = true
			delete(vm, "debug")
		}

		if s, ok := vm["custom_data"].(string); ok {
			userCfg.UserData = s
		}

		userdata, err := s.Session.Userdata.Create(userCfg)
		if err != nil {
			return nil, err
		}

		vm["user_data"] = string(userdata)

		// create independent kiteKey for each machine and create a Terraform
		// lookup map, which is used in conjuctuon with the `count.index`
		countKeys := make(map[string]string, count)
		for i, label := range labels {
			kiteKey, err := s.BuildKiteKey(label, s.Req.Username)
			if err != nil {
				return nil, err
			}

			countKeys[strconv.Itoa(i)] = kiteKey
		}

		t.Variable[kiteKeyName] = map[string]interface{}{
			"default": countKeys,
		}

		res.AzureInstance[name] = vm
	}

	t.Resource["azure_instance"] = res.AzureInstance

	if err := t.Flush(); err != nil {
		return nil, err
	}

	if err := t.ShadowVariables("FORBIDDEN", "azure_publish_settings", "azure_settings_file"); err != nil {
		return nil, err
	}

	content, err := t.JsonOutput()
	if err != nil {
		return nil, err
	}

	return &stack.Template{
		Content: content,
	}, nil
}

func newBootstrapTmpl(cfg *BootstrapConfig) ([]byte, error) {
	var buf bytes.Buffer

	if err := tmpl.Execute(&buf, cfg); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func mustAsset(s string) string {
	p, err := Asset(s)
	if err != nil {
		panic(err)
	}
	return string(p)
}

func endpointsIndex(endpoints []interface{}, name string) int {
	for i, v := range endpoints {
		endpoint, ok := v.(map[string]interface{})
		if !ok {
			continue
		}

		s, ok := endpoint["name"].(string)
		if !ok {
			continue
		}

		if strings.EqualFold(s, name) {
			return i
		}
	}

	return -1
}
