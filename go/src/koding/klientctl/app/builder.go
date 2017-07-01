package app

import (
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"strings"
	"sync"
	"time"

	"koding/kites/config"
	kstack "koding/kites/kloud/stack"
	"koding/kites/kloud/stack/provider"
	kmachine "koding/klient/machine"
	"koding/klient/machine/machinegroup"
	"koding/klientctl/app/mixin"
	konfig "koding/klientctl/config"
	"koding/klientctl/endpoint/credential"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/machine"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/endpoint/stack"
	"koding/klientctl/helper"
	"koding/remoteapi/models"

	"github.com/koding/logging"
	"golang.org/x/sync/errgroup"
	yaml "gopkg.in/yaml.v2"
)

// DefaultBuilder is used by global functions, like app.BuildTemplate,
// app.BuildStack etc.
var DefaultBuilder = &Builder{}

// Builder allows for manipulating contents of stack
// templates in a provider-agnostic manner.
type Builder struct {
	Desc kstack.Descriptions // provider description; retrieved from kloud, if nil
	Log  logging.Logger      // logger; kloud.DefaultLog if nil

	Koding     *remoteapi.Client  // remote.api client; remoteapi.DefaultClient if nil
	Kloud      *kloud.Client      // kloud client; kloud.DefaultClient if nil
	Credential *credential.Client // credential client; credential.DefaultClient if nil
	Stack      *stack.Client      // stack client; stack.DefaultClient if nil
	Machine    *machine.Client    // machine client; machine.DefaultClient if nil
	Klient     kloud.Transport    // local klient client; uses default 127.0.0.1:56789 url  if nil
	Konfig     *config.Konfig

	Stdout io.Writer // stdout to write; os.Stdout if nil
	Stderr io.Writer // stderr to write; os.Stderr if nil

	once  sync.Once       // for b.init()
	local kloud.Transport // default client for Klient
}

// TemplateOptions are used when building a template.
type TemplateOptions struct {
	UseDefaults bool         // forces default value when true; disables interactive mode
	Provider    string       // provider name; inferred from Template if empty
	Template    string       // base template to use; retrieved from remote.api's samples, if empty
	Mixin       *mixin.Mixin // mixin to replace default's user_data; mixin.App if nil
}

func (opts *TemplateOptions) mixin() *mixin.Mixin {
	if opts.Mixin != nil {
		return opts.Mixin
	}
	return mixin.App
}

// BuildTemplate builds a template with the given options.
//
// If method finishes successfully, returning nil error, b.Stack field
// will hold the built template.
func (b *Builder) BuildTemplate(opts *TemplateOptions) (interface{}, map[string]string, error) {
	b.init()

	var (
		defaults map[string]interface{}
		tmpl     = opts.Template
		prov     = opts.Provider
		err      error
	)

	if tmpl == "" {
		if prov == "" {
			return nil, nil, errors.New("either provider or template is required to be non-empty")
		}

		tmpl, defaults, err = b.koding().SampleTemplate(prov)
		if err != nil {
			return nil, nil, err
		}
	}

	if prov == "" {
		prov, err = kstack.ReadProvider([]byte(tmpl))
		if err != nil {
			return nil, nil, err
		}
	}

	desc, ok := b.Desc[prov]
	if !ok {
		return nil, nil, fmt.Errorf("provider %q does not exist", prov)
	}

	if desc.CloudInit {
		t, err := replaceUserData(tmpl, opts.mixin(), desc)
		if err != nil {
			return nil, nil, err
		}

		p, err := json.Marshal(t)
		if err != nil {
			return nil, nil, err
		}

		tmpl = string(p)

		for _, v := range opts.mixin().Variable {
			defaults[v.Name] = v.Default
		}
	}

	vars := provider.ReadVariables(tmpl)
	input := make(map[string]string, len(vars))

	for _, v := range vars {
		if !strings.HasPrefix(v.Name, "userInput_") {
			continue
		}

		if _, ok := input[v.Name]; ok {
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
				return nil, nil, err
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

	var v interface{}

	if err := json.Unmarshal([]byte(tmpl), &v); err != nil {
		return nil, nil, err
	}

	return v, input, nil
}

type StackOptions struct {
	Team        string
	Title       string
	Credentials []string
	Template    []byte
	File        string
	UseDefaults bool
}

func (opts *StackOptions) template() ([]byte, error) {
	if opts.Template != nil {
		return opts.Template, nil
	}

	var err error

	switch opts.File {
	case "":
		err = errors.New("no template file was provided")
	case "-":
		opts.Template, err = ioutil.ReadAll(os.Stdin)
	default:
		opts.Template, err = ioutil.ReadFile(opts.File)
	}

	return opts.Template, err
}

// BuildStack builds a compute stack with the given options.
//
// After the stack is successfully created it waits until
// the stack is successfully built and until user_data
// script finishes execution.
func (b *Builder) BuildStack(opts *StackOptions) (*models.JComputeStack, []*models.JMachine, error) {
	b.init()

	p, err := opts.template()
	if err != nil {
		return nil, nil, err
	}

	fmt.Fprintln(b.stderr(), "Creating stack... ")

	if !opts.UseDefaults && opts.Title == "" {
		providers, err := kstack.ReadProvidersWithUnmarshal(p, yaml.Unmarshal)
		if err != nil {
			return nil, nil, errors.New("unable to read provider name: " + err.Error())
		}

		defTitle := strings.Title(kstack.Pokemon() + " " + providers[0] + " Stack")

		opts.Title, err = helper.Ask("\nStack name [%s]: ", defTitle)
		if err != nil {
			return nil, nil, err
		}
		if opts.Title == "" {
			opts.Title = defTitle
		}
	}

	o := &stack.CreateOptions{
		Team:        opts.Team,
		Title:       opts.Title,
		Credentials: opts.Credentials,
		Template:    p,
	}

	resp, err := b.stack().Create(o)
	if err != nil {
		return nil, nil, errors.New("error creating stack: " + err.Error())
	}

	fmt.Fprintf(b.stderr(), "\nCreated %q stack with %s ID.\nWaiting for your stack to finish building...\n\n", resp.Title, resp.StackID)

	for e := range b.kloud().Wait(resp.EventID) {
		if e.Error != nil {
			return nil, nil, fmt.Errorf("\nBuilding %q stack failed:\n%s\n", resp.Title, e.Error)
		}

		fmt.Fprintf(b.stderr(), "[%d%%] %s\n", e.Event.Percentage, e.Event.Message)
	}

	s, err := b.koding().Stack(&remoteapi.Filter{ID: resp.StackID})
	if err != nil {
		return nil, nil, err
	}

	m, err := b.machines(s)
	if err != nil {
		return nil, nil, err
	}

	if err := b.wait(m); err != nil {
		return nil, nil, err
	}

	return s, m, nil
}

func (b *Builder) wait(m []*models.JMachine) error {
	var eg errgroup.Group

	fmt.Fprintf(b.stderr(), "\nWaiting for your stack to finish provisioning...\n\n")

	for _, m := range m {
		m := m

		eg.Go(func() error {
			done := make(chan int, 1)

			fn := func(line string) {
				if strings.Contains(line, "_KD_DONE_") {
					done <- 0
					return
				}

				fmt.Fprintf(b.stderr(), "%s | %s\n", m.Slug, line)
			}

			opts := &machine.ExecOptions{
				MachineID:     m.ID,
				Cmd:           "tail",
				Args:          []string{"-f", "/var/log/cloud-init-output.log"},
				Stdout:        fn,
				Stderr:        fn,
				Exit:          func(exit int) { done <- exit },
				WaitConnected: 30 * time.Second,
			}

			pid, err := b.machine().Exec(opts)
			if err != nil {
				return err
			}

			defer b.machine().Kill(&machine.KillOptions{MachineID: m.ID, PID: pid})

			if exit := <-done; exit != 0 {
				return fmt.Errorf("%s: failed with exit code: %d", m.Slug, exit)
			}

			return nil
		})
	}

	return eg.Wait()
}

func (b *Builder) machines(s *models.JComputeStack) ([]*models.JMachine, error) {
	v, ok := s.Machines.([]interface{})
	if !ok {
		return nil, fmt.Errorf("unexpected machines field: %T", s.Machines)
	}
	if len(v) == 0 {
		return nil, errors.New("no machines found")
	}

	machines := make([]*models.JMachine, 0, len(v))

	for i, v := range v {
		var m *models.JMachine

		switch v := v.(type) {
		case string:
			var err error
			m, err = b.koding().Machine(&remoteapi.Filter{ID: v})
			if err != nil {
				return nil, fmt.Errorf("%s: %s", v, err)
			}
		case map[string]interface{}:
			// TODO(rjeczalik): Research if there exists anything that
			// allows for converting map[string]interface{} to concerete
			// struct without going through JSON encoding.
			p, err := json.Marshal(v)
			if err != nil {
				return nil, fmt.Errorf("%d: %s", i, err)
			}
			if err := json.Unmarshal(p, &m); err != nil {
				return nil, fmt.Errorf("%d: %s", i, err)
			}
		}

		if m == nil {
			return nil, fmt.Errorf("%d: unexpected machine id: %T", i, v)
		}

		machines = append(machines, m)
	}

	// TODO(rjeczalik): Move this to klient, so its cache does not
	// need to be populated externally when one creates machines
	// with remote.api.
	// Register machines to klient and get aliases.
	createReq := &machinegroup.CreateRequest{
		Addresses: make(map[kmachine.ID][]kmachine.Addr),
	}

	for _, m := range machines {
		now := time.Now()

		createReq.Addresses[kmachine.ID(m.ID)] = []kmachine.Addr{{
			Network:   "ip",
			Value:     m.IPAddress,
			UpdatedAt: now,
		}, {
			Network:   "kite",
			Value:     m.QueryString,
			UpdatedAt: now,
		}}

		// TODO(rjeczalik): add JMachine.registerUrl to swagger schema
	}

	if err := b.klient().Call("machine.create", createReq, nil); err != nil {
		return nil, err
	}

	return machines, nil
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

	if b.Klient == nil {
		b.local = &kloud.KiteTransport{
			ClientURL: b.konfig().Endpoints.Klient.Private.String(),
		}
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

func (b *Builder) stack() *stack.Client {
	if b.Stack != nil {
		return b.Stack
	}
	return stack.DefaultClient
}

func (b *Builder) stdout() io.Writer {
	if b.Stdout != nil {
		return b.Stdout
	}
	return os.Stdout
}

func (b *Builder) stderr() io.Writer {
	if b.Stderr != nil {
		return b.Stderr
	}
	return os.Stderr
}

func (b *Builder) kloud() *kloud.Client {
	if b.Kloud != nil {
		return b.Kloud
	}
	return kloud.DefaultClient
}

func (b *Builder) machine() *machine.Client {
	if b.Machine != nil {
		return b.Machine
	}
	return machine.DefaultClient
}

func (b *Builder) klient() kloud.Transport {
	if b.Klient != nil {
		return b.Klient
	}
	return b.local
}

func (b *Builder) konfig() *config.Konfig {
	if b.Konfig != nil {
		return b.Konfig
	}
	return konfig.Konfig
}

func replaceUserData(tmpl string, m *mixin.Mixin, desc *kstack.Description) (map[string]interface{}, error) {
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

// BuildStack builds a compute stack with the given options.
//
// After the stack is successfully created it waits until
// the stack is successfully built and until user_data
// script finishes execution.
func BuildStack(opts *StackOptions) (*models.JComputeStack, []*models.JMachine, error) {
	return DefaultBuilder.BuildStack(opts)
}

// BuildTemplate builds a template with the given options.
//
// If method finishes successfully, returning nil error, b.Stack field
// will hold the built template.
func BuildTemplate(opts *TemplateOptions) (interface{}, map[string]string, error) {
	return DefaultBuilder.BuildTemplate(opts)
}
