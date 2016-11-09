package softlayer

import (
	"bytes"
	"errors"
	"fmt"
	"strconv"
	"text/template"

	// "koding/kites/kloud/api/sl"
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

// Read in bootstrap template
func mustAsset(s string) string {
	a, err := Asset(s)
	if err != nil {
		panic(err)
	}
	return string(a)
}

var BootstrapTemplate = template.Must(template.New("").Parse(mustAsset("bootstrap.json.tmpl")))

type bootstrapVars struct {
	KeyName 		string
	PublicKey   string
	Username		string
	ApiKey			string
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

// Returns provisioning templates that will be executed with provided Credential.
func (s *Stack) BootstrapTemplates(c *stack.Credential) ([]*stack.Template, error) {
	fmt.Println("Entered BootstrapTemplates()")

	cred := c.Credential.(*Credential)
	fmt.Printf("The scope's creds are %s %s", cred.Username, cred.ApiKey)

	vs := &bootstrapVars{
		KeyName: fmt.Sprintf(
			"koding-%s-%s",
			s.Req.Username,
			c.Identifier,
		),
		PublicKey: s.Keys.PublicKey,
		Username: cred.Username,
		ApiKey: cred.ApiKey,
	}

	var bootstrap bytes.Buffer
	if err := BootstrapTemplate.Execute(&bootstrap, vs); err != nil {
		return nil, err
	}

	fmt.Println(bootstrap.String())

	fmt.Println("Leaving BootstrapTemplates()")

	return []*stack.Template{{
		Content: bootstrap.String(),
	}}, nil
}

// Responsible for ensuring each new Softlayer instance will
// connect to Koding upon start.
func (s *Stack) ApplyTemplate(c *stack.Credential) (*stack.Template, error) {
	// TODO: In order to connect to Koding, two things must happen
	// TODO: 1. Generate kite.key for each instance
	// TODO: 2. Provision Klient on each instance with kite.key

	fmt.Println("Entered ApplyTemplate()")

	t := s.Builder.Template

	cred := c.Credential.(*Credential)
	bootstrap := c.Bootstrap.(*Bootstrap)

	t.Provider["softlayer"] = map[string]interface{}{
		"username": cred.Username,
		"api_key": cred.ApiKey,
	}

	keyID, err := strconv.Atoi(bootstrap.KeyID)
	if err != nil {
		return nil, err
	}

	///////////////
	var resource struct {
		VirtualGuest map[string]map[string]interface{} `hcl:"softlayer_virtual_guest"`
	}

	if err := s.Builder.Template.DecodeResource(&resource); err != nil {
		return nil, err
	}

	if len(resource.VirtualGuest) == 0 {
		return nil, errors.New("There are no virtual guests available")
	}

	// There might be multiple virtual guests, need to iterate here
	for name, guest := range resource.VirtualGuest {

		// TODO: handle user override for ssh keys
		guest["ssh_keys"] = []int{keyID}

		// Check image input
		if _, ok := guest["image"]; !ok {
			guest["image"] = "UBUNTU_14_64"
		}

		// Each machine must have a unique kite id, setup count interpolation
		count := 1
		if n, ok := guest["count"].(int); ok && n > 1 {
			count = n
		}

		labels := []string{name}
		if count > 1 {
			for i := 0; i < count; i++ {
				labels = append(labels, fmt.Sprintf("%s.%d", name, i))
			}
		}

		kiteKeyName := fmt.Sprintf("kitekey_%s", name)

		s.Builder.InterpolateField(guest, name, "user_data")

		userConfig := &userdata.CloudInitConfig{
			Username: s.Req.Username,
			Groups: []string{"sudo"},
			Hostname: s.Req.Username,
			KiteKey: fmt.Sprintf("${lookup(var.%s, count.index)}", kiteKeyName),
		}

		if s, ok := guest["user_data"].(string); ok {
			userConfig.UserData = s
		}

		userdata, err := s.Session.Userdata.Create(userConfig)
		if err != nil {
			return nil, err
		}

		guest["user_data"] = string(userdata)

		// Create kite key for each instance and create a Terraform lookup map
		// which is used in conjuntion with the `count.index`
		countKeys := make(map[string]string, count)
		for i, label := range labels {
			kiteKey, err := s.BuildKiteKey(label, s.Req.Username)
			if err != nil {
				return nil, err
			}

			countKeys[strconv.Itoa(i)] = kiteKey
		}

		s.Builder.Template.Variable[kiteKeyName] = map[string]interface{}{
			"default": countKeys,
		}

		resource.VirtualGuest[name] = guest
	}
	///////////////

	t.Resource["softlayer_virtual_guest"] = resource.VirtualGuest

	if err := t.ShadowVariables("FORBIDDEN", "softlayer_api_key"); err != nil {
		return nil, err
	}

	if err := t.Flush(); err != nil {
		return nil, err
	}

	content, err := t.JsonOutput()
	if err != nil {
		return nil, err
	}

	fmt.Println(t)

	fmt.Println("Leaving ApplyTemplate()")

	return &stack.Template{
		Content: content,
	}, nil
}
