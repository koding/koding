package softlayer

import (
	"bytes"
	"errors"
	"fmt"
	"strconv"
	"text/template"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

	softlayer "github.com/maximilien/softlayer-go/client"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1475345133 -pkg softlayer -o bootstrap.json.tmpl.go bootstrap.json.tmpl
//go:generate gofmt -l -w -s bootstrap.json.tmpl.go

var (
	_ provider.Stack = (*Stack)(nil)
	_ stack.Stacker  = (*Stack)(nil)
)

func mustAsset(s string) string {
	a, err := Asset(s)
	if err != nil {
		panic(err)
	}
	return string(a)
}

var BootstrapTemplate = template.Must(template.New("").Parse(mustAsset("bootstrap.json.tmpl")))

type bootstrapVars struct {
	KeyName   string
	PublicKey string
}

// Responsible for building/updating/destroying Softlayer's stack
type Stack struct {
	*provider.BaseStack

	sshKeyPair *stack.SSHKeyPair
}

// Verifies the given Softlayer credential.
// Compared against what is defined in schema.Credential.
func (s *Stack) VerifyCredential(c *stack.Credential) error {
	cred, ok := c.Credential.(*Credential)
	if !ok {
		return fmt.Errorf("credential is not of type softlayer.Credential: %T", c.Credential)
	}

	if err := cred.Valid(); err != nil {
		return err
	}

	// Do a quick check to verify the credentials are valid for
	// communitcating with the SoftLayer apis
	client := softlayer.NewSoftLayerClient(cred.Username, cred.ApiKey)
	account, err := client.GetSoftLayer_Account_Service()
	if err != nil {
		return err
	}

	_, err = account.GetAccountStatus()
	return err
}

func (s *Stack) BootstrapArg() *stack.BootstrapRequest {
	return s.BaseStack.Arg.(*stack.BootstrapRequest)
}

// BootstrapTemplates creates the template that is used to generate default
// output values, to bootstrap a SoftLayer stack
func (s *Stack) BootstrapTemplates(c *stack.Credential) ([]*stack.Template, error) {
	vs := &bootstrapVars{
		KeyName:   s.sshKeyPair.Name,
		PublicKey: string(s.sshKeyPair.Public),
	}

	var bootstrap bytes.Buffer
	if err := BootstrapTemplate.Execute(&bootstrap, vs); err != nil {
		return nil, err
	}

	return []*stack.Template{{
		Content: bootstrap.String(),
	}}, nil
}

// injectBootstrap injects bootstrap resources into a SoftLayer stack, which
// is to say, it provides specific default values if user doesn't provide them
func (s *Stack) injectBootstrap(b *Bootstrap, guest map[string]interface{}) error {
	bootstrapKey, err := strconv.Atoi(b.KeyID)
	if err != nil {
		return err
	}

	// Apply user ssh keys if provided, otherwise use the bootstrap key
	keys := []int{bootstrapKey}

	if userKeys, ok := guest["ssh_keys"].([]int); ok {
		keys = append(keys, userKeys...)
	}
	guest["ssh_keys"] = keys

	if gid, ok := guest["block_device_template_group_gid"]; !ok || gid == "" {
		if image, ok := guest["image"].(string); !ok || image == "" {
			guest["image"] = "UBUNTU_14_64"
		}
	}

	return nil
}

// ApplyTemplate injects bootstrap resources into a SoftLayer stack,
// and is responsible for ensuring each new Softlayer instance will
// connect to Koding upon start.
func (s *Stack) ApplyTemplate(c *stack.Credential) (*stack.Template, error) {
	t := s.Builder.Template

	var resource struct {
		VirtualGuest map[string]map[string]interface{} `hcl:"softlayer_virtual_guest"`
	}

	// Decode the user provided stack template, searching for
	// virtual guest definitions
	if err := s.Builder.Template.DecodeResource(&resource); err != nil {
		return nil, err
	}

	// If user hasn't specified a virtual guest definitions
	// in their stack, then we have nothing else to do
	if len(resource.VirtualGuest) == 0 {
		return nil, errors.New("No softlayer_virtual_guest resources were defined in stack.")
	}

	bootstrap := c.Bootstrap.(*Bootstrap)

	// Iterate through n softlayer_virtual_guest definitions, filling in
	// configuration gaps with bootstrap, and setting up kite keys with
	// cloud-init for each.
	for name, guest := range resource.VirtualGuest {
		if err := s.injectBootstrap(bootstrap, guest); err != nil {
			return nil, err
		}

		if err := s.BuildUserdata(name, guest); err != nil {
			return nil, err
		}
	}

	t.Resource["softlayer_virtual_guest"] = resource.VirtualGuest

	// Don't show secret things in frontend logs to the user
	if err := t.ShadowVariables("FORBIDDEN", "api_key"); err != nil {
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

func (s *Stack) setSSHKeyPair(keypair *stack.SSHKeyPair) error {
	s.sshKeyPair = keypair
	return nil
}
