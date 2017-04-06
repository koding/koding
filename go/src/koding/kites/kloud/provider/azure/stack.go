package azure

import (
	"bytes"
	"errors"
	"strconv"
	"strings"
	"text/template"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/tools/utils"

	"github.com/Azure/azure-sdk-for-go/management"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1470666525 -pkg azure -o bootstrap.json.tmpl.go bootstrap.json.tmpl
//go:generate gofmt -l -w -s bootstrap.json.tmpl.go

var tmpl = template.Must(template.New("").Parse(string(MustAsset("bootstrap.json.tmpl"))))

// BootstrapConfig represents configuration for bootstrap template.
type BootstrapConfig struct {
	TeamSlug           string
	HostedServiceName  string
	StorageType        string
	AddressSpace       string
	StorageServiceName string
	SubnetName         string
	SecurityGroupName  string
	VirtualNetworkName string
	Rule               bool
}

// Endpoint represents a single Azure's endpoint rule.
type Endpoint struct {
	Name        string `json:"name" hcl:"name"`
	Protocol    string `json:"protocol" hcl:"protocol"`
	PublicPort  int    `json:"public_port" hcl:"public_port"`
	PrivatePort int    `json:"private_port" hcl:"private_port"`
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

// Cred gives Azure's credential.
func (s *Stack) Cred() *Cred {
	return s.BaseStack.Credential.(*Cred)
}

// Bootstrap gives Azure's bootstrap metadata.
func (s *Stack) Bootstrap() *Bootstrap {
	return s.BaseStack.Bootstrap.(*Bootstrap)
}

// BootstrapArg gives bootstrap request for the given request.
func (s *Stack) BootstrapArg() *stack.BootstrapRequest {
	return s.BaseStack.Arg.(*stack.BootstrapRequest)
}

// VerifyCredential verifies the given Azure credential.
func (s *Stack) VerifyCredential(c *stack.Credential) error {
	cred := c.Credential.(*Cred)

	if err := cred.Valid(); err != nil {
		return err
	}

	client, err := management.ClientFromPublishSettingsData([]byte(cred.PublishSettings), cred.SubscriptionID)
	if err != nil {
		return err
	}

	err = client.WaitForOperation("invalid", nil)
	if err != nil && !strings.Contains(err.Error(), "The operation request ID was not found") {
		return err
	}

	return nil
}

func substringN(s string, n int) string {
	if len(s) > n {
		return s[:n]
	}

	return s
}

// BootstrapTemplates returns bootstrap templates that are used
// to bootstrap an Azure stack.
func (s *Stack) BootstrapTemplates(c *stack.Credential) ([]*stack.Template, error) {
	cred := c.Credential.(*Cred)
	boot := c.Bootstrap.(*Bootstrap)

	cfg := &BootstrapConfig{
		TeamSlug:           s.BootstrapArg().GroupName,
		HostedServiceName:  "koding-hs-" + c.Identifier,
		StorageType:        string(cred.Storage),
		AddressSpace:       boot.addressSpace(),
		StorageServiceName: substringN(strings.ToLower("kodings"+c.Identifier), 24),
		SecurityGroupName:  "koding-sg-" + c.Identifier,
		VirtualNetworkName: "koding-vn-" + c.Identifier,
		SubnetName:         "koding-su-" + c.Identifier,
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

// ApplyTemplate injects bootstrap resources into an Azure's stack.
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
		// Set ssh_key_thumbprint if not provided explicitly.
		if cred.SSHKeyThumbprint != "" {
			if thumb, ok := vm["ssh_key_thumbprint"]; !ok || thumb == "" {
				vm["ssh_key_thumbprint"] = cred.SSHKeyThumbprint
			}
		}

		s.injectPasswords(vm, cred, "passwords_"+name)

		s.injectBoostrap(vm, cred, boot)

		s.injectEndpointRules(vm)

		if err := s.BuildUserdata(name, vm); err != nil {
			return nil, err
		}

		res.AzureInstance[name] = vm
	}

	t.Resource["azure_instance"] = res.AzureInstance

	if err := t.ShadowVariables("FORBIDDEN", "azure_publish_settings", "azure_settings_file"); err != nil {
		return nil, err
	}

	if err := t.Flush(); err != nil {
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

func (s *Stack) injectBoostrap(vm map[string]interface{}, cred *Cred, boot *Bootstrap) {
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
}

// sainitizePassword sanitizes a password before injecting it
// into Terraform template. If the generate string contained
// a "${" character sequence, plan and apply request are
// going to fail with:
//
//   * Variable 'passwords_azure-instance': cannot contain interpolations
//
var sanitizePassword = strings.NewReplacer("${", "@{")

func (s *Stack) injectPasswords(vm map[string]interface{}, cred *Cred, passwordVar string) {
	pass, ok := vm["password"]
	if ok && pass != "" {
		return
	}

	count := 1
	if n, ok := vm["count"].(int); ok && n > 1 {
		count = n
	}

	passwords := make(map[string]string, count)

	for i := 0; i < count; i++ {
		pass := cred.Password
		if pass == "" {
			pass = sanitizePassword.Replace(utils.Pwgen(16))
		}

		passwords[strconv.Itoa(i)] = pass
	}

	vm["password"] = "${lookup(var." + passwordVar + ", count.index)}"

	s.Builder.Template.Variable[passwordVar] = map[string]interface{}{
		"default": passwords,
	}
}

func (s *Stack) injectEndpointRules(vm map[string]interface{}) {
	endpoints, ok := vm["endpoint"].([]interface{})
	if !ok {
		if e, ok := vm["endpoint"].([]map[string]interface{}); ok {
			for _, e := range e {
				endpoints = append(endpoints, e)
			}
		}
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
}

func newBootstrapTmpl(cfg *BootstrapConfig) ([]byte, error) {
	var buf bytes.Buffer

	if err := tmpl.Execute(&buf, cfg); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
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
