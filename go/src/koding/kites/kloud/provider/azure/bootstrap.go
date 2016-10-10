package azure

import (
	"bytes"
	"fmt"
	"strings"
	"text/template"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/terraformer"
	tf "koding/kites/terraformer"

	"golang.org/x/net/context"
)

//go:generate $GOPATH/bin/go-bindata -mode 420 -modtime 1470666525 -pkg azure -o bootstrap.json.tmpl.go bootstrap.json.tmpl
//go:generate gofmt -w -s bootstrap.json.tmpl.go

var tmpl = template.Must(template.New("").Parse(mustAsset("bootstrap.json.tmpl")))

type BootstrapConfig struct {
	TeamSlug           string
	HostedServiceName  string
	StorageServiceName string
	SecurityGroupName  string
	VirtualNetworkName string
	Rule               bool
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

func (s *Stack) Bootstrap(context.Context) (interface{}, error) {
	var arg stack.BootstrapRequest
	if err := s.Req.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}

	return s.bootstrap(&arg)
}

func (s *Stack) bootstrap(arg *stack.BootstrapRequest) (interface{}, error) {
	if err := arg.Valid(); err != nil {
		return nil, err
	}

	if err := s.BuildCredentials(arg.GroupName, arg.Identifiers); err != nil {
		return nil, err
	}

	tfKite, err := terraformer.Connect(s.Session.Terraformer)
	if err != nil {
		return nil, err
	}
	defer tfKite.Close()

	meta := s.Cred()
	contentID := fmt.Sprintf("azure-%s-%s", arg.GroupName, s.c.Identifier)

	// Important so bootstraping is distributed amongs multiple users. If I
	// use these keys to bootstrap, any other user should be not create
	// again, instead they should be fetch and use the existing bootstrap
	// data.

	if arg.Destroy {
		// TODO(rjeczalik): bootstrap destroy should use already existing
		// terraform files and not build templates again.

		s.Log.Info("Destroying bootstrap resources belonging to identifier '%s'", s.c.Identifier)

		_, err := tfKite.Destroy(&tf.TerraformRequest{
			ContentID: contentID,
			TraceID:   s.TraceID,
		})
		if err != nil {
			return nil, err
		}

		meta.ResetBootstrap()
	} else {
		s.Log.Info("Creating bootstrap resources belonging to identifier '%s'", s.c.Identifier)

		cfg := &BootstrapConfig{
			TeamSlug:           arg.GroupName,
			HostedServiceName:  fmt.Sprintf("koding-hs-%s", s.c.Identifier),
			StorageServiceName: strings.ToLower("kodings" + s.c.Identifier),
			SecurityGroupName:  fmt.Sprintf("koding-sg-%s", s.c.Identifier),
			VirtualNetworkName: fmt.Sprintf("koding-vn-%s", s.c.Identifier),
			Rule:               false,
		}

		// If credentials have already storage service configured, do not create it.
		if meta.StorageServiceID != "" {
			cfg.StorageServiceName = ""
		}

		s.Log.Debug("Building template: %s", contentID)

		bootstrapTmpl, err := newBootstrapTmpl(cfg)
		if err != nil {
			return nil, err
		}

		state, err := tfKite.Apply(&tf.TerraformRequest{
			Content:   string(bootstrapTmpl),
			ContentID: contentID,
			TraceID:   s.TraceID,
		})
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

		_, err = tfKite.Apply(&tf.TerraformRequest{
			Content:   string(ruleTmpl),
			ContentID: contentID,
			TraceID:   s.TraceID,
		})
		if err != nil {
			return nil, err
		}

		s.Log.Debug("[%s] state.RootModule().Outputs = %+v\n", s.c.Identifier, state.RootModule().Outputs)

		if err := s.Builder.Object.Decode(state.RootModule().Outputs, meta); err != nil {
			return nil, err
		}

		s.Log.Debug("[%s] resp = %+v\n", s.c.Identifier, meta)

		if err := meta.BootstrapValid(); err != nil {
			return nil, fmt.Errorf("invalid bootstrap metadata for %q: %s", s.c.Identifier, err)
		}
	}

	s.Log.Debug("[%s] Bootstrap response: %+v", s.c.Identifier, meta)

	datas := map[string]interface{}{
		s.c.Identifier: meta,
	}

	if err := s.Builder.CredStore.Put(s.Req.Username, datas); err != nil {
		return nil, err
	}

	return true, nil
}
