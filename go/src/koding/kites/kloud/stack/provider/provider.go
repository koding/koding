package provider

import (
	"sync"
	"time"

	"koding/db/models"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/machinestate"
	"koding/kites/kloud/stack"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
)

var (
	providersMu   sync.RWMutex
	providers     = make(map[string]*Provider)
	providerDescs = make(map[string]*stack.Description)
)

func Register(p *Provider) {
	providersMu.Lock()
	defer providersMu.Unlock()

	if p == nil {
		panic("stack: Register provider is nil")
	}
	if p.Name == "" {
		panic("stack: Register provider name is empty")
	}
	if _, dup := providers[p.Name]; dup {
		panic("stack: Register called twice for " + p.Name)
	}

	providers[p.Name] = p
	providerDescs[p.Name] = &stack.Description{
		Provider:   p.Name,
		Credential: mustDescribe(schema(p.Name).newCredential()),
		Bootstrap:  mustDescribe(schema(p.Name).newBootstrap()),
		UserData:   p.userdataPath(),
		CloudInit:  !p.NoCloudInit,
	}
}

func All() []*Provider {
	providersMu.RLock()
	defer providersMu.RUnlock()

	all := make([]*Provider, 0, len(providers))

	for _, p := range providers {
		all = append(all, p)
	}

	return all
}

func Desc(providers ...string) map[string]*stack.Description {
	providersMu.RLock()
	defer providersMu.RUnlock()

	return desc(providers...)
}

func desc(providers ...string) map[string]*stack.Description {
	nonempty := make([]string, 0, len(providers))

	for _, p := range providers {
		if p != "" {
			nonempty = append(nonempty, p)
		}
	}

	desc := make(map[string]*stack.Description)

	if len(nonempty) == 0 {
		for k, v := range providerDescs {
			desc[k] = v
		}
	} else {
		for _, k := range nonempty {
			if v, ok := providerDescs[k]; ok {
				desc[k] = v
			}
		}
	}

	return desc
}

// Provider describes a single kloud provider.
//
// A kloud provider is used to enrich terraform template
// with koding-related data and bootstrapped resources.
//
// Also it provides support for koding-related attributes
// available for each terraform template.
//
// TODO(rjeczalik): Deprecate Userdata in favor of UserdataPath.
type Provider struct {
	// Name is a name of the provider.
	//
	// Required.
	Name string

	// ResourceName is a name of the machine resource.
	//
	// If empty, "instance" will be used instead.
	ResourceName string

	// Userdata is a name of user_data field containing
	// post-provision user scipt.
	//
	// If empty, "user_data" will be used instead.
	Userdata string

	// UserdataPath specifies the JSONPath to the user_data
	// field for each instance.
	//
	// E.g. given the resource name is instance for aws
	// provider its UserdataPath is {"aws_instance", "*", "user_data"}.
	//
	// If UserdataPath is nil, the following JSONPath is used
	// by default:
	//
	//   []string{Name + "_" + ResourceName, "*", Userdata}
	//
	UserdataPath []string

	// NoCloudInit is set to true by provider, if it does
	// not support running cloud-init scripts.
	NoCloudInit bool

	// Machine creates a Machine value, that is responsible
	// for managing lifetime of a single machine
	// within user's stack (start/stop etc.).
	//
	// Required.
	Machine func(*BaseMachine) (Machine, error)

	// Stack creates new Stack value, that handles Koding flavor
	// of user's Terraform templates. By augumenting user's stack
	// template it takes care of injecting Klient / Koding metadata
	// into the template.
	//
	// Required.
	Stack func(*BaseStack) (Stack, error)

	// Schema represents data structures which are
	// used when transferring information throughout
	// a number parts of the Koding system.
	//
	// If nil, DefaultSchema will be used instead.
	Schema *Schema
}

// DefaultSchema describes default schema used,
// when a registered provider has a nil Schema.
var DefaultSchema = &Schema{
	NewCredential: func() interface{} { return make(map[string]interface{}) },
	NewBootstrap:  nil,
	NewMetadata: func(m *stack.Machine) interface{} {
		if m == nil {
			return make(map[string]interface{})
		}

		return m.Attributes
	},
}

type Schema struct {
	// NewCredential is called when unmarshaling credential information
	// from a JSON-encdoded value obtained from a secure store.
	//
	// If either NewCredential field or the returned credential
	// is nil, DefaultSchema.NewCredential is going to be used instead.
	NewCredential func() (credential interface{})

	// NewBootstrap is called when unmarshaling bootstrap information
	// from a JSON-encoded value obtained from a secure store.
	//
	// If either NewBootstrap field or the returned v is nil,
	// no bootstrap data will be read or written.
	NewBootstrap func() (bootstrap interface{})

	// NewMetadata is called when unmarshaling machine metadata
	// from a BSON-encoded value obtained from Koding database.
	//
	// If the given Machine is nil, NewMetadata is expected
	// to return a zero-value of the metadata.
	//
	// If NewMetadata field is nil, DefaultSchema.NewMetadata
	// is going to be used instead.
	NewMetadata func(*stack.Machine) (metadata interface{})
}

type Stack interface {
	VerifyCredential(*stack.Credential) error
	BootstrapTemplates(*stack.Credential) ([]*stack.Template, error)
	ApplyTemplate(*stack.Credential) (*stack.Template, error)
}

type Machine interface {
	Start(context.Context) (metadata interface{}, err error)
	Stop(context.Context) (metadata interface{}, err error)
	Info(context.Context) (state machinestate.State, metadata interface{}, err error)
}

// BaseStack provides shared implementation of team handler for use
// with external provider-specific handlers.
type BaseStack struct {
	Log      logging.Logger
	Req      *kite.Request
	Builder  *Builder
	Session  *session.Session
	Provider *Provider

	Arg        interface{}
	Credential interface{}
	Bootstrap  interface{}

	Keys      *publickeys.Keys
	Eventer   eventer.Eventer
	Planner   *Planner
	KlientIDs stack.KiteMap
	Klients   map[string]*DialState
	Metas     map[string]map[string]interface{}
	TunnelURL string

	Debug   bool
	TraceID string

	// PlanFunc is used by HandlePlan method to
	// build a list of machines created by
	// a particular stack.
	//
	// If PlanFunc is nil, default implementation
	// is used, which is provided by (*BaseStack).Plan.
	// The default implementation creates a list
	// of machine by sending a plan request
	// to terraformer and reading the plan
	// state file.
	PlanFunc func() (stack.Machines, error)

	// SSHKeyPairFunc is used by HandleBootstrap
	// to inject a newly generated SSH keypair
	// into provider's bootstrap data.
	//
	// If the function is non-nil, BaseStack will
	// generate a new SSH keypair and expect
	// provider implementation will add it
	// to its bootstrap template.
	//
	// SSHKeyPairFunc can overwrite keypair's fields
	// to any other values.
	SSHKeyPairFunc func(keypair *stack.SSHKeyPair) error

	// StateFunc is used by HandleApply method to
	// build a list of machines to update after
	// a successful apply operation.
	//
	// If StateFunc is nil, default implementation
	// is used, which is provided by (*Planner).MachinesFromState.
	StateFunc func(*terraform.State, map[string]*DialState) (map[string]*stack.Machine, error)

	stack Stack
}

func (bs *BaseStack) plan() (stack.Machines, error) {
	if bs.PlanFunc != nil {
		return bs.PlanFunc()
	}

	return bs.Plan()
}

func (bs *BaseStack) state(state *terraform.State) (map[string]*stack.Machine, error) {
	if bs.StateFunc != nil {
		return bs.StateFunc(state, bs.Klients)
	}

	return bs.Planner.MachinesFromState(state, bs.Klients, bs.Metas)
}

type BaseMachine struct {
	*session.Session
	*models.Machine

	Credential interface{}
	Bootstrap  interface{}
	Metadata   interface{}

	KlientTimeout time.Duration
	Provider      string
	TraceID       string
	Debug         bool
	User          *models.User
	Req           *kite.Request

	machine Machine
}

func (p *Provider) resourceName() string {
	if p.ResourceName != "" {
		return p.ResourceName
	}

	return "instance"
}

func (p *Provider) newCredential() interface{} {
	return p.Schema.newCredential()
}

func (ps *Schema) newCredential() interface{} {
	if ps != nil && ps.NewCredential != nil {
		return ps.NewCredential()
	}

	if DefaultSchema != nil && DefaultSchema.NewCredential != nil {
		return DefaultSchema.NewCredential()
	}

	return make(map[string]interface{})
}

func (p *Provider) newBootstrap() interface{} {
	return p.Schema.newBootstrap()
}

func (ps *Schema) newBootstrap() interface{} {
	if ps != nil && ps.NewBootstrap != nil {
		return ps.NewBootstrap()
	}

	if DefaultSchema != nil && DefaultSchema.NewBootstrap != nil {
		return DefaultSchema.NewBootstrap()
	}

	return nil
}

func (p *Provider) newMetadata(m *stack.Machine) interface{} {
	return p.Schema.newMetadata(m)
}

func (p *Provider) userdata() string {
	if p.Userdata != "" {
		return p.Userdata
	}
	return "user_data"
}

func (p *Provider) userdataPath() []string {
	if p.UserdataPath != nil {
		return p.UserdataPath
	}
	return []string{p.Name + "_" + p.resourceName(), "*", p.userdata()}
}

func (ps *Schema) newMetadata(m *stack.Machine) interface{} {
	if ps != nil && ps.NewMetadata != nil {
		return ps.NewMetadata(m)
	}

	if DefaultSchema != nil && DefaultSchema.NewMetadata != nil {
		return DefaultSchema.NewMetadata(m)
	}

	return make(map[string]interface{})
}
