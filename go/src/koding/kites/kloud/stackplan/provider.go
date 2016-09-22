package stackplan

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
	providersMu sync.RWMutex
	providers   = make(map[string]*Provider)
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

type Provider struct {
	// Name is a name of the provider.
	//
	// Required.
	Name string

	// ResourceName is a name of the machine resource.
	//
	// If empty, "instance" will be used instead.
	ResourceName string

	// NewMachine
	//
	// Required.
	NewMachine func(*BaseMachine) (Machine, error)

	// NewStack
	//
	// Required.
	NewStack func(*BaseStack) (Stack, error)

	// Schema
	//
	// If nil, GenericSchema will be used instead.
	Schema *ProviderSchema
}

var GenericSchema = &ProviderSchema{
	NewCredential: func() interface{} { return make(map[string]interface{}) },
	NewBootstrap:  nil,
	NewMetadata:   func() interface{} { return make(map[string]interface{}) },
}

type ProviderSchema struct {
	// NewCredential
	//
	// If either NewCredential field or the returned v is nil,
	// a map[string]interface{} value will be used instead.
	NewCredential func() (v interface{})

	// NewBootstrap
	//
	// If either NewBootstrap field or the returned v is nil,
	// no bootstrap data is read or written.
	NewBootstrap func() (v interface{})

	// NewMetadata
	//
	// If either NewMetadata field or the returned v is nil,
	// a map[string]interface{} value will be used instead.
	NewMetadata func() (v interface{})
}

type Stack interface {
	// VerifyCredential
	VerifyCredential(*stack.Credential) error

	// BootstrapTemplates
	BootstrapTemplates(*stack.Credential) ([]*stack.Template, error)

	// BuildResources
	BuildResources(*stack.Credential) error

	// BuildMetadata
	BuildMetadata(*stack.Machine) interface{}

	// The following methods are executed as a handlers for a kite request.
	//
	// They are implemented by a *BaseStack value.
	//
	// If provider requires custom handling for any of the methods,
	// it should shadow the default implementation or do not embed
	// the *BaseStack value.
	HandleApply(context.Context) (interface{}, error)
	HandleAuthenticate(context.Context) (interface{}, error)
	HandleBootstrap(context.Context) (interface{}, error)
	HandlePlan(context.Context) (interface{}, error)
}

type Machine interface {
	// Start
	Start(context.Context) error

	// Stop
	Stop(context.Context) error

	// Info
	Info(context.Context) (*stack.InfoResponse, error)

	// The following methods are implemented by a *BaseMachine value.
	//
	// If machine requires custom handling for any of the methods,
	// it should shadow the default implementation or do not embed
	// the *BaseMachine value.
	State() machinestate.State
	ProviderName() string
}

// BaseStack provides shared implementation of team handler for use
// with external provider-specific handlers.
type BaseStack struct {
	Log      logging.Logger
	Req      *kite.Request
	Builder  *Builder
	Session  *session.Session
	Provider *Provider

	Credential interface{}
	Bootstrap  interface{}

	Keys      *publickeys.Keys
	Eventer   eventer.Eventer
	Stack     Stack
	Planner   *Planner
	KlientIDs stack.KiteMap
	Klients   map[string]*DialState

	Debug      bool
	TraceID    string
	Identifier string
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
}

// InfoResponse is returned from a info method
type InfoResponse struct {
	// State defines the state of the machine
	State machinestate.State `json:"state"`

	// Name defines the name of the machine.
	Name string `json:"name,omitempty"`

	// InstanceType defines the type of the given machine
	InstanceType string `json:"instanceType,omitempty"`
}

func (p *Provider) resourceName() string {
	if p.ResourceName != "" {
		return p.ResourceName
	}

	return "instance"
}

func (p *Provider) newCredential() interface{} {
	if p.Schema != nil && p.Schema.NewCredential != nil {
		return p.Schema.NewCredential()
	}

	if GenericSchema != nil && GenericSchema.NewCredential != nil {
		return GenericSchema.NewCredential()
	}

	return make(map[string]interface{})
}

func (p *Provider) newBootstrap() interface{} {
	if p.Schema != nil && p.Schema.NewBootstrap != nil {
		return p.Schema.NewBootstrap()
	}

	if GenericSchema != nil && GenericSchema.NewBootstrap != nil {
		return GenericSchema.NewBootstrap()
	}

	return nil
}

func (p *Provider) newMetadata() interface{} {
	if p.Schema != nil && p.Schema.NewMetadata != nil {
		return p.Schema.NewMetadata()
	}

	if GenericSchema != nil && GenericSchema.NewMetadata != nil {
		return GenericSchema.NewMetadata()
	}

	return make(map[string]interface{})
}
