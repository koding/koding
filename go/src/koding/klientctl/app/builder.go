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

// Builder allows for manipulating contents of stack
// templates in a provider-agnostic manner.
type Builder struct {
	Stack object.Object // the resulting stack object

	Desc stack.Descriptions // provider description; retrieved from kloud, if nil
	Log  logging.Logger     // logger; kloud.DefaultLog if nil

	Koding     *remoteapi.Client  // remote.api client; remoteapi.DefaultClient if nil
	Credential *credential.Client // credential client; credential.DefaultClient if nil

	once sync.Once // for b.init()
}

// TemplateOptions are used when building a template.
type TemplateOptions struct {
	UseDefaults bool         // forces default value when true; disables interactive mode
	Provider    string       // provider name; inferred from Template if empty
	Template    string       // base template to use; retrieved from remote.api's samples, if empty
	Mixin       *mixin.Mixin // optionally a mixin to replace default's user_data
}

// BuildTemplate builds a template with the given options.
//
// If method finishes successfully, returning nil error, b.Stack field
// will hold the built template.
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

		t, err := replaceUserData(tmpl, opts.Mixin, desc)
		if err != nil {
			return err
		}

		p, err := json.Marshal(t)
		if err != nil {
			return err
		}

		tmpl = string(p)
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

func replaceUserData(tmpl string, m *mixin.Mixin, desc *stack.Description) (map[string]interface{}, error) {
	var (
		root map[string]interface{}
		key  string
		keys = append([]string{"resource"}, desc.UserData...)
		ok   bool
	)

	if err := json.Unmarshal([]byte(tmpl), &root); err != nil {
		return nil, err
	}

	machines := root

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
			return nil, fmt.Errorf("template does not contain %q key: %v", key, desc.UserData)
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
				machine[key] = m.CloudInit.String()
				break
			}

			machine, ok = machine[key].(map[string]interface{})
			if !ok {
				return nil, fmt.Errorf("template does not contain %q key: %v", key, desc.UserData)
			}
		}
	}

	return root, nil
}
