package app

import (
	"encoding/json"
	"fmt"
	"strings"
	"sync"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/klientctl/app/mixin"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/helper"

	"github.com/koding/logging"
)

type Builder struct {
	Desc     stack.Descriptions
	Template map[string]interface{}
	Log      logging.Logger

	Remote     *remoteapi.Client
	Credential *credential.Client

	once sync.Once
}

type TemplateOptions struct {
	UseDefaults bool
	Provider    string
	Mixin       *mixin.Mixin
}

func (b *Builder) BuildTemplate(opts *TemplateOptions) error {
	b.init()

	desc, ok := b.Desc[opts.Provider]
	if !ok {
		return fmt.Errorf("provider %q does not exist", opts.Provider)
	}

	tmpl, defaults, err := b.remoteapi().SampleTemplate(opts.Provider)
	if err != nil {
		return err
	}

	vars := provider.ReadVariables(tmpl)
	input := make(map[string]string, len(vars))

	for _, v := range vars {
		if !strings.HasPrefix(v.Name, "userInput_") {
			continue
		}

		name := v.Name[len("userInput_"):]
		defValue := ""
		if v, ok := defaults[name]; ok && v != nil {
			defValue = fmt.Sprintf("%v", v)
		}

		var value string

		if !opts.UseDefaults {
			if value, err = helper.Ask("Set %q to [%s]: ", name, defValue); err != nil {
				return err
			}
		}

		if value == "" {
			value = defValue
		}

		input[v.Name] = value
	}

	tmpl = provider.ReplaceVariablesFunc(tmpl, vars, func(v *provider.Variable) string {
		if s, ok := input[v.Name]; ok {
			return s
		}

		return v.String()
	})

	if err := json.Unmarshal([]byte(tmpl), &b.Template); err != nil {
		return err
	}

	if desc.CloudInit && opts.Mixin != nil {
		machines, ok := b.Template, false

		for _, k := range desc.UserData {
			if k == "*" {
				break
			}

			machines, ok = machines[k].(map[string]interface{})
			if !ok {
				return fmt.Errorf("%s: unable to inject cloud init into %v", opts.Provider, desc.UserData)
			}
		}

		for _, v := range machines {
			m, ok := v.(map[string]interface{})
			if !ok {
				continue
			}

			for k, v := range opts.Mixin.Machine {
				m[k] = v
			}
		}

		// TODO: inject cloud-init
	}

	// TODO(rjeczalik):
	// - build stack
	// - wait for stack
	// - copy user files
	// - build application
	// - display url

	return nil
}

func (b *Builder) init() {
	b.once.Do(b.initBuilder)
}

func (b *Builder) initBuilder() {
	if b.Desc == nil {
		var err error
		if b.Desc, err = b.credential().Describe(); err != nil {
			b.log().Warning("unable to retrieve credential description: %s", err)
		}
	}
}

func (b *Builder) log() logging.Logger {
	if b.Log != nil {
		return b.Log
	}
	return kloud.DefaultLog
}

func (b *Builder) remote() *remoteapi.Client {
	if b.Remote != nil {
		return b.Remote
	}
	return remoteapi.DefaultClient
}

func (b *Builder) credential() *credential.Client {
	if b.Credential != nil {
		return b.Credential
	}
	return credential.DefaultClient
}
