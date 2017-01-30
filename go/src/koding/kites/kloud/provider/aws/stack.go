package aws

import (
	"bytes"
	"fmt"
	"strconv"
	"text/template"
	"time"

	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/userdata"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1470666525 -pkg aws -o bootstrap.json.tmpl.go bootstrap.json.tmpl
//go:generate $GOPATH/bin/gofmt -l -w -s bootstrap.json.tmpl.go

var bootstrap = template.Must(template.New("").Parse(mustAsset("bootstrap.json.tmpl")))

type bootstrapConfig struct {
	AvailabilityZone string
	KeyPairName      string
	PublicKey        string
	EnvironmentName  string
}

// Stack implements the stackplan.Stack interface.
type Stack struct {
	*provider.BaseStack
}

var (
	_ provider.Stack = (*Stack)(nil) // public API
	_ stack.Stacker  = (*Stack)(nil) // internal API
)

func (s *Stack) VerifyCredential(c *stack.Credential) error {
	cred := c.Credential.(*Cred)

	if err := cred.Valid(); err != nil {
		return err
	}

	_, err := amazon.NewClient(cred.Options())
	if err != nil {
		return &stack.Error{
			Err: err,
		}
	}

	return nil
}

func (s *Stack) BootstrapTemplates(c *stack.Credential) ([]*stack.Template, error) {
	cred := c.Credential.(*Cred)

	opts := cred.Options()
	opts.Log = s.Log.New("amazon")

	cfg := &bootstrapConfig{
		AvailabilityZone: "${lookup(var.aws_availability_zones, var.aws_region)}",
		KeyPairName:      fmt.Sprintf("koding-deployment-%s-%s-%d", s.Req.Username, s.BootstrapArg().GroupName, time.Now().UTC().UnixNano()),
		PublicKey:        s.Keys.PublicKey,
		EnvironmentName:  fmt.Sprintf("Koding-%s-Bootstrap", s.BootstrapArg().GroupName),
	}

	if client, err := amazon.NewClient(opts); err == nil && len(client.Zones) != 0 {
		cfg.AvailabilityZone = client.Zones[0]
	} else {
		s.Log.Warning("unable to guess availability zones for %q: %s", c.Identifier, err)
	}

	t, err := newBootstrapTemplate(cfg)
	if err != nil {
		return nil, err
	}

	if accountID, err := cred.AccountID(); err == nil {
		t.Key = accountID + "-" + s.BootstrapArg().GroupName + "-" + c.Identifier
	} else {
		s.Log.Warning("unable to read account ID for %q: %s", c.Identifier, err)
	}

	s.Log.Debug("bootstrap template key: %q", t.Key)

	return []*stack.Template{t}, nil
}

func (s *Stack) ApplyTemplate(c *stack.Credential) (*stack.Template, error) {
	t := s.Builder.Template
	cred := c.Credential.(*Cred)
	bootstrap := c.Bootstrap.(*Bootstrap)

	if err := s.SetAwsRegion(string(cred.Region)); err != nil {
		return nil, err
	}

	var resource struct {
		AwsInstance map[string]map[string]interface{} `hcl:"aws_instance"`
	}

	if err := t.DecodeResource(&resource); err != nil {
		return nil, err
	}

	if len(resource.AwsInstance) == 0 {
		return nil, fmt.Errorf("instances are empty: %v", resource.AwsInstance)
	}

	for resourceName, instance := range resource.AwsInstance {
		// Do not overwrite SSH key pair with the bootstrap one
		// when user sets it explicitly in a template.
		if s, ok := instance["key_name"]; !ok || s == "" {
			instance["key_name"] = bootstrap.KeyPair
		}

		// if nothing is provided or the ami is empty use default Ubuntu AMI's
		if a, ok := instance["ami"]; !ok {
			instance["ami"] = bootstrap.AMI
		} else {
			if ami, ok := a.(string); ok && ami == "" {
				instance["ami"] = bootstrap.AMI
			}
		}

		// only ovveride if the user doesn't provider it's own subnet_id
		if instance["subnet_id"] == nil {
			instance["subnet_id"] = bootstrap.Subnet
			instance["security_groups"] = []string{bootstrap.SG}
		}

		// means there will be several instances, we need to create a userdata
		// with count interpolation, because each machine must have an unique
		// kite id.
		count := 1
		if n, ok := instance["count"].(int); ok && n > 1 {
			count = n
		}

		var labels []string
		if count > 1 {
			for i := 0; i < count; i++ {
				labels = append(labels, fmt.Sprintf("%s.%d", resourceName, i))
			}
		} else {
			labels = append(labels, resourceName)
		}

		// TODO(rjeczalik): move to stackplan
		if b, ok := instance["debug"].(bool); ok && b {
			s.Debug = true
			delete(instance, "debug")
		}

		kiteKeyName := fmt.Sprintf("kitekeys_%s", resourceName)

		s.Builder.InterpolateField(instance, resourceName, "user_data")

		// this part will be the same for all machines
		userCfg := &userdata.CloudInitConfig{
			Username: s.Req.Username,
			Groups:   []string{"sudo"},
			Hostname: s.Req.Username, // no typo here. hostname = username
			KiteKey:  fmt.Sprintf("${lookup(var.%s, count.index)}", kiteKeyName),
		}

		if s, ok := instance["user_data"].(string); ok {
			userCfg.UserData = s
		}

		userdata, err := s.Session.Userdata.Create(userCfg)
		if err != nil {
			return nil, err
		}

		instance["user_data"] = string(userdata)

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

		resource.AwsInstance[resourceName] = instance
	}

	t.Resource["aws_instance"] = resource.AwsInstance

	// TODO(rjeczalik): move to stackplan
	err := t.ShadowVariables("FORBIDDEN", "aws_access_key", "aws_secret_key")
	if err != nil {
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

func (s *Stack) SetAwsRegion(region string) error {
	t := s.Builder.Template

	var p struct {
		Aws struct {
			Region    string `hcl:"region"`
			AccessKey string `hcl:"access_key"`
			SecretKey string `hcl:"secret_key"`
		}
	}

	if err := t.DecodeProvider(&p); err != nil {
		return err
	}

	if p.Aws.Region == "" {
		t.Provider["aws"] = map[string]interface{}{
			"region":     region,
			"access_key": p.Aws.AccessKey,
			"secret_key": p.Aws.SecretKey,
		}
	} else if !provider.IsVariable(p.Aws.Region) && p.Aws.Region != region {
		return fmt.Errorf("region is already set as '%s'. Can't override it with: %s",
			p.Aws.Region, region)
	}

	return t.Flush()
}

func (s *Stack) Credential() *Cred {
	return s.BaseStack.Credential.(*Cred)
}

func (s *Stack) Bootstrap() *Bootstrap {
	return s.BaseStack.Bootstrap.(*Bootstrap)
}

func (s *Stack) BootstrapArg() *stack.BootstrapRequest {
	return s.BaseStack.Arg.(*stack.BootstrapRequest)
}

func mustAsset(s string) string {
	p, err := Asset(s)
	if err != nil {
		panic(err)
	}
	return string(p)
}

func newBootstrapTemplate(cfg *bootstrapConfig) (*stack.Template, error) {
	var buf bytes.Buffer

	if err := bootstrap.Execute(&buf, cfg); err != nil {
		return nil, err
	}

	return &stack.Template{
		Content: buf.String(),
	}, nil
}
