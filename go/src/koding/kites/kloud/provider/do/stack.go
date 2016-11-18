package do

import (
	"bytes"
	"errors"
	"fmt"
	"html/template"
	"strconv"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/userdata"

	"github.com/digitalocean/godo"
	"golang.org/x/oauth2"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1470666525 -pkg do -o bootstrap.json.tmpl.go bootstrap.json.tmpl
//go:generate go fmt bootstrap.json.tmpl.go

var bootstrapTmpl = template.Must(
	template.New("").Parse(string(MustAsset("bootstrap.json.tmpl"))),
)

const (
	defaultUbuntuImage = "ubuntu-14-04-x64"
)

var _ provider.Stack = (*Stack)(nil)

// Stack is responsible of handling the terraform templates
type Stack struct {
	*provider.BaseStack

	sshKeyPair *stack.SSHKeyPair
}

func newStack(bs *provider.BaseStack) (provider.Stack, error) {
	s := &Stack{
		BaseStack: bs,
	}

	bs.SSHKeyPairFunc = s.setSSHKeyPair

	return s, nil
}

// VerifyCredential verifies whether the users DO credentials (access token) is
// valid or not
func (s *Stack) VerifyCredential(c *stack.Credential) error {
	cred := c.Credential.(*Credential)

	if err := cred.Valid(); err != nil {
		return err
	}

	oauthClient := oauth2.NewClient(
		oauth2.NoContext,
		oauth2.StaticTokenSource(&oauth2.Token{AccessToken: cred.AccessToken}),
	)

	client := godo.NewClient(oauthClient)

	// let's retrieve our Account information. If it's successful, we're good
	// to go
	_, _, err := client.Account.Get()
	if err != nil {
		return &stack.Error{
			Err: err,
		}
	}

	return nil
}

func (s *Stack) setSSHKeyPair(keypair *stack.SSHKeyPair) error {
	s.sshKeyPair = keypair
	return nil
}

// BootstrapTemplates returns terraform templates that needs to be executed
// before a droplet is created. In our case we'll create a template that
// creates a ssh key on behalf of Koding, that will be later used during
// ApplyTemplate()
func (s *Stack) BootstrapTemplates(c *stack.Credential) ([]*stack.Template, error) {
	type tmplData struct {
		KeyName   string
		PublicKey string
	}

	// fill the template
	var buf bytes.Buffer
	if err := bootstrapTmpl.Execute(&buf, &tmplData{
		KeyName:   s.sshKeyPair.Name,
		PublicKey: string(s.sshKeyPair.Public),
	}); err != nil {
		return nil, err
	}

	return []*stack.Template{
		{Content: buf.String()},
	}, nil
}

// ApplyTemplate enhances and updates the DigitalOcean terraform template. It
// updates the various sections of the template, such as Provider, Resources,
// Variables, etc... so it can be executed without any problems
func (s *Stack) ApplyTemplate(c *stack.Credential) (*stack.Template, error) {
	cred, ok := c.Credential.(*Credential)
	if !ok {
		return nil, fmt.Errorf("credential is not of type do.Credential: %T", c.Credential)
	}

	bootstrap, ok := c.Bootstrap.(*Bootstrap)
	if !ok {
		return nil, fmt.Errorf("bootstrap is not of type do.Bootstrap: %T", c.Bootstrap)
	}

	template := s.Builder.Template
	template.Provider["digitalocean"] = map[string]interface{}{
		"token": cred.AccessToken,
	}

	keyID, err := strconv.Atoi(bootstrap.KeyID)
	if err != nil {
		return nil, err
	}

	droplet, err := s.modifyDroplets(keyID)
	if err != nil {
		return nil, err
	}

	template.Resource["digitalocean_droplet"] = droplet

	if err := template.ShadowVariables("FORBIDDEN", "digitalocean_access_token"); err != nil {
		return nil, err
	}

	if err := template.Flush(); err != nil {
		return nil, err
	}

	content, err := template.JsonOutput()
	if err != nil {
		return nil, err
	}

	return &stack.Template{
		Content: content,
	}, nil
}

// modifyDroplets returns a modified 'digitalocean_droplet' terraform resource
// from the stack that changes things like image, injects kite and ssh_key,
// etc...
func (s *Stack) modifyDroplets(keyID int) (map[string]map[string]interface{}, error) {
	var resource struct {
		Droplet map[string]map[string]interface{} `hcl:"digitalocean_droplet"`
	}

	if err := s.Builder.Template.DecodeResource(&resource); err != nil {
		return nil, err
	}

	if len(resource.Droplet) == 0 {
		return nil, errors.New("there are no droplets available")
	}

	// we might have multipel droplets, iterate over all of them
	for dropletName, droplet := range resource.Droplet {
		// Do not overwrite SSH key pair with the bootstrap one
		// when user sets it explicitly in a template.
		if s, ok := droplet["ssh_keys"]; !ok {
			droplet["ssh_keys"] = []int{keyID}
		} else if keyIds, ok := s.([]int); ok {
			keys := []int{keyID}
			if len(keyIds) != 0 {
				keys = append(keys, keyIds...)
			}

			droplet["ssh_keys"] = keys
		}

		// if nothing is provided or the image is empty use default Ubuntu image
		if i, ok := droplet["image"]; !ok {
			droplet["image"] = defaultUbuntuImage
		} else if image, ok := i.(string); ok && image == "" {
			droplet["image"] = defaultUbuntuImage
		}

		// means there will be several instances, we need to create a userdata
		// with count interpolation, because each machine must have an unique
		// kite id.
		count := 1
		if n, ok := droplet["count"].(int); ok && n > 1 {
			count = n
		}

		var labels []string
		if count > 1 {
			for i := 0; i < count; i++ {
				labels = append(labels, fmt.Sprintf("%s.%d", dropletName, i))
			}
		} else {
			labels = append(labels, dropletName)
		}

		kiteKeyName := fmt.Sprintf("kitekeys_%s", dropletName)

		s.Builder.InterpolateField(droplet, dropletName, "user_data")

		// this part will be the same for all machines
		userCfg := &userdata.CloudInitConfig{
			Username: s.Req.Username,
			Groups:   []string{"sudo"},
			Hostname: s.Req.Username, // no typo here. hostname = username
			KiteKey:  fmt.Sprintf("${lookup(var.%s, count.index)}", kiteKeyName),
		}

		if s, ok := droplet["user_data"].(string); ok {
			userCfg.UserData = s
		}

		userdata, err := s.Session.Userdata.Create(userCfg)
		if err != nil {
			return nil, err
		}

		droplet["user_data"] = string(userdata)

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

		s.Builder.Template.Variable[kiteKeyName] = map[string]interface{}{
			"default": countKeys,
		}

		resource.Droplet[dropletName] = droplet
	}

	return resource.Droplet, nil
}

// BootstrapArg returns the bootstrap argument made to the bootrap kite
func (s *Stack) BootstrapArg() *stack.BootstrapRequest {
	return s.BaseStack.Arg.(*stack.BootstrapRequest)
}
