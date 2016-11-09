package softlayer

import (
	"bytes"
	"errors"
	"fmt"
	"strconv"
	"text/template"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/userdata"

	softlayerGo "github.com/maximilien/softlayer-go/client"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1475345133 -pkg softlayer -o bootstrap.json.tmpl.go bootstrap.json.tmpl
//go:generate go fmt bootstrap.json.tmpl.go

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
	client := softlayerGo.NewSoftLayerClient(cred.Username, cred.ApiKey)
	service, err := client.GetSoftLayer_Virtual_Guest_Service()
	if err != nil {
		return err
	}
	_, err = service.GetObject(1234567)
	if err != nil {
		return err
	}

	return nil
}

func (s *Stack) BootstrapArg() *stack.BootstrapRequest {
	return s.BaseStack.Arg.(*stack.BootstrapRequest)
}

// BootstrapTemplates creates the template that is used to generate default
// output values, to bootstrap a SoftLayer stack
func (s *Stack) BootstrapTemplates(c *stack.Credential) ([]*stack.Template, error) {
	vs := &bootstrapVars{
		KeyName: fmt.Sprintf(
			"koding-%s",
			c.Identifier,
		),
		PublicKey: s.Keys.PublicKey,
	}

	var bootstrap bytes.Buffer
	if err := BootstrapTemplate.Execute(&bootstrap, vs); err != nil {
		return nil, err
	}

	// NOTE: Should we shadow out private vars here?

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

	guest["image"] = "UBUNTU_14_64"
	// NOTE: Should we allow for user override here? Do all images work with klient?
	if userImage, ok := guest["image"]; ok {
		guest["image"] = userImage
	}

	return nil
}

// injectKiteKeys creates a kite key for each virtual guest, and sets up
// the runtime injection of said key using cloud-init/user_data
func (s *Stack) injectKiteKeys(guest map[string]interface{}, name string) error {
	s.Builder.InterpolateField(guest, name, "user_data")

	kiteKey, err := s.BuildKiteKey(name, s.Req.Username)
	if err != nil {
		return err
	}

	// Map the generated kite key to the guest via cloud-init config
	cloudInitConfig := &userdata.CloudInitConfig{
		Username: s.Req.Username,
		Groups:   []string{"sudo"},
		Hostname: s.Req.Username,
		KiteKey:  kiteKey,
	}

	// If user provided user data, associate that with our cloud init config
	if ud, ok := guest["user_data"].(string); ok {
		cloudInitConfig.UserData = ud
	}

	// Create cloud init and associate with guest
	cloudInit, err := s.Session.Userdata.Create(cloudInitConfig)
	if err != nil {
		return err
	}
	guest["user_data"] = string(cloudInit)

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

		if err := s.injectKiteKeys(guest, name); err != nil {
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
