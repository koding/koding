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

	nonempty := make([]string, 0, len(providers))

	for _, p := range providers {
		if p != "" {
			nonempty = append(nonempty, p)
		}
	}

	n := len(nonempty)
	if n == 0 {
		n = len(providerDescs)
	}

	desc := make(map[string]*stack.Description, n)

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

type Provider struct {
	// Name is a name of the provider.
	//
	// Required.
	Name string

	// ResourceName is a name of the machine resource.
	//
	// If empty, "instance" will be used instead.
	ResourceName string

	// Machine
	//
	// Required.
	Machine func(*BaseMachine) (Machine, error)

	// Stack
	//
	// Required.
	Stack func(*BaseStack) (Stack, error)

	// Schema
	//
	// If nil, DefaultSchema will be used instead.
	Schema *Schema
}

// DefaultSchema TODO!
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
	// NewCredential
	//
	// If either NewCredential field or the returned credential
	// is nil, DefaultSchema.NewCredential is going to be used instead.
	NewCredential func() (credential interface{})

	// NewBootstrap
	//
	// If either NewBootstrap field or the returned v is nil,
	// no bootstrap data will be read or written.
	NewBootstrap func() (bootstrap interface{})

	// NewMetadata
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
	TunnelURL string

	Debug   bool
	TraceID string

	stack Stack
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

func (ps *Schema) newMetadata(m *stack.Machine) interface{} {
	if ps != nil && ps.NewMetadata != nil {
		return ps.NewMetadata(m)
	}

	if DefaultSchema != nil && DefaultSchema.NewMetadata != nil {
		return DefaultSchema.NewMetadata(m)
	}

	return make(map[string]interface{})
}
