package app

import (
	"encoding/json"
	"errors"
	"fmt"
	"strings"
	"sync"

	"koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	"koding/kites/kloud/utils/object"
	"koding/klientctl/app/mixin"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/helper"

	"github.com/koding/logging"
)

type Builder struct {
	Stack object.Object

	Desc stack.Descriptions
	Log  logging.Logger

	Koding     *remoteapi.Client
	Credential *credential.Client

	once sync.Once
}

type TemplateOptions struct {
	UseDefaults bool
	Provider    string
	Template    string
	Mixin       *mixin.Mixin
}

func (b *Builder) BuildTemplate(opts *TemplateOptions) error {
	b.init()

	var (
		defaults map[string]interface{}
		tmpl     = opts.Template
		prov     = opts.Provider
		err      error
	)

	if tmpl == "" {
		if prov == "" {
			return errors.New("either provider or template is required to be non-empty")
		}

		tmpl, defaults, err = b.koding().SampleTemplate(prov)
		if err != nil {
			return err
		}
	}

	if prov == "" {
		prov, err = stack.ReadProvider([]byte(tmpl))
		if err != nil {
			return err
		}
	}

	desc, ok := b.Desc[prov]
	if !ok {
		return fmt.Errorf("provider %q does not exist", prov)
	}

	if opts.Mixin != nil {
		if !desc.CloudInit {
			return fmt.Errorf("provider %q does not support cloud-init files", prov)
		}

		tmpl, err = replaceUserData(tmpl, opts.Mixin, desc)
		if err != nil {
			return err
		}
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

	return json.Unmarshal([]byte(tmpl), &b.Stack)

	// TODO(rjeczalik):
	// - build stack
	// - wait for stack
	// - copy user files
	// - build application
	// - display url
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

	if b.Stack == nil {
		b.Stack = make(object.Object)
	}
}

func (b *Builder) log() logging.Logger {
	if b.Log != nil {
		return b.Log
	}
	return kloud.DefaultLog
}

func (b *Builder) koding() *remoteapi.Client {
	if b.Koding != nil {
		return b.Koding
	}
	return remoteapi.DefaultClient
}

func (b *Builder) credential() *credential.Client {
	if b.Credential != nil {
		return b.Credential
	}
	return credential.DefaultClient
}

func replaceUserData(tmpl string, m *mixin.Mixin, desc *stack.Description) (string, error) {
	var (
		root      map[string]interface{}
		key, keys = "", desc.UserData
		machines  = root
		ok        bool
	)

	if err := json.Unmarshal([]byte(tmpl), &root); err != nil {
		return "", err
	}

	// The desc.UserData is a JSON path to a user_data value
	// inside the resource tree. Considering the following desc.UserData:
	//
	//   []string{"google_compute_instance", "*", "metadata", "user-data"}
	//
	// the following is going to traverse the template until we assign
	// to machines a value under the * key.
	for len(keys) > 0 {
		key, keys = keys[0], keys[1:]

		if key == "*" {
			break
		}

		machines, ok = machines[key].(map[string]interface{})
		if !ok {
			return "", fmt.Errorf("template does not contain %q key: %v", key, desc.UserData)
		}
	}

	// The following loop assignes extra attributes to each machine and
	// replaces user_data with mixin.
	for _, v := range machines {
		machine, ok := v.(map[string]interface{})
		if !ok {
			continue
		}

		for k, v := range m.Machine {
			machine[k] = v
		}

		// For each machine we locate the user_data by traversing
		// the path after the *.
		for len(keys) > 0 {
			key, keys = keys[0], keys[1:]

			if len(keys) == 0 {
				machine[key] = m.CloudInit
				break
			}

			machine, ok = machine[key].(map[string]interface{})
			if !ok {
				return "", fmt.Errorf("template does not contain %q key: %v", key, desc.UserData)
			}
		}
	}

	p, err := json.Marshal(root)
	if err != nil {
		return "", err
	}

	return string(p), nil
}
