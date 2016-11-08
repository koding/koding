package softlayer

import (
	"bytes"
	"fmt"
	"text/template"

	// "koding/kites/kloud/api/sl"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"

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
	// bootstrap := c.Bootstrap.(*Bootstrap)

	fmt.Printf("Credential: Username=%s ApiKeyLength=%d", cred.Username, len(cred.ApiKey))

	t.Provider["softlayer"] = map[string]interface{}{
		"username": cred.Username,
		"api_key": cred.ApiKey,
	}

	// var resource struct {
	// 	SLVirtualGuest map[string]map[string]interface{} `hcl:"softlayer_virtual_guest"`
	// }

	if err := t.Flush(); err != nil {
		return nil, err
	}

	content, err := t.JsonOutput()
	if err != nil {
		return nil, err
	}

	fmt.Println("Leaving ApplyTemplate()")

	return &stack.Template{
		Content: content,
	}, nil
}
