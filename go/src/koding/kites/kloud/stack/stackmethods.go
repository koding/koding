package stack

import (
	"errors"
	"sort"
	"time"

	"gopkg.in/mgo.v2/bson"

	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/kites/kloud/machinestate"

	"github.com/koding/cache"
	"github.com/koding/kite"
)

// KiteMap maps resource names to kite IDs they own.
type KiteMap map[string]string

// Stack is struct that contains all necessary information Apply needs to
// perform successfully.
type Stack struct {
	ID bson.ObjectId // jComputeStack._id

	// Machines is a list of jMachine identifiers.
	Machines []string

	// Credentials maps jCredential provider to identifiers.
	Credentials map[string][]string

	// Template is a raw Terraform template.
	Template string

	// Stack is a jComputeStack value.
	Stack *models.ComputeStack
}

// Credential represents jCredential{Datas} value. Meta is of a provider-specific
// type, defined by a ctor func in MetaFuncs map.
type Credential struct {
	Title      string
	Provider   string
	Identifier string
	Credential interface{}
	Bootstrap  interface{}
}

// Machine represents a jComputeStack.machine value.
type Machine struct {
	// Fields set by kloud.plan:
	Provider   string            `json:"provider"`
	Label      string            `json:"label"`
	Attributes map[string]string `json:"attributes"`

	// Fields set by kloud.apply:
	QueryString string             `json:"queryString,omitempty"`
	RegisterURL string             `json:"registerURL,omitempty"`
	State       machinestate.State `json:"state,omitempty"`
	StateReason string             `json:"stateReason,omitempty"`
}

// Machines represents group of machines mapped by a label.
type Machines map[string]*Machine

// Slice gives list of machines sorted by a label.
func (m Machines) Slice() []*Machine {
	labels := make([]string, 0, len(m))

	for label := range m {
		labels = append(labels, label)
	}

	sort.Strings(labels)

	machines := make([]*Machine, 0, len(m))

	for _, label := range labels {
		machines = append(machines, m[label])
	}

	return machines
}

type Template struct {
	Key     string // unique terraformer key for a given template; optional
	Content []byte // terraformer template content; required
}

// Validator validates and returns non-nil error when it's ill-formed.
//
// For use with model, request and response structs.
type Validator interface {
	Valid() error
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

/// APPLY

// ApplyRequest represents an argument of apply kite method.
type ApplyRequest struct {
	Provider  string `json:"provider"`
	StackID   string `json:"stackId"`
	GroupName string `json:"groupName"`

	// Credentials sets or overrides credentials set in jStackTemplate or
	// jComputeStack.
	Credentials map[string][]string `json:"credentials,omitempty"`

	// Destroy, when true, destroys the terraform tempalte associated with the
	// given StackId.
	Destroy bool
}

// Valid implements the Validator interface.
func (req *ApplyRequest) Valid() error {
	if req.StackID == "" {
		return errors.New("stackId is empty")
	}
	if req.GroupName == "" {
		return errors.New("groupName is empty")
	}
	return nil
}

// Apply provides apply as a kite method.
func (k *Kloud) Apply(r *kite.Request) (interface{}, error) {
	return k.stackMethod(r, Stacker.HandleApply)
}

/// AUTHENTICATE

// AuthenticateRequest represents an argument of the authenticate kite method.
type AuthenticateRequest struct {
	Provider string `json:"provider"`

	// Identifiers contains identifiers to be authenticated
	Identifiers []string `json:"identifiers"`

	GroupName string `json:"groupName"`
}

type AuthenticateResult struct {
	Verified bool   `json:"verified"`
	Message  string `json:"message,omitempty"`
}

type AuthenticateResponse map[string]*AuthenticateResult

// Valid implements the Validator interface.
func (req *AuthenticateRequest) Valid() error {
	if len(req.Identifiers) == 0 {
		return errors.New("identifiers are not passed")
	}
	if req.GroupName == "" {
		return errors.New("group name is not passed")
	}
	return nil
}

// Authenticate provides authenticate as a kite method.
func (k *Kloud) Authenticate(r *kite.Request) (interface{}, error) {
	return k.stackMethod(r, Stacker.HandleAuthenticate)
}

/// BOOTSTRAP

// BootstrapRequest represents an argument of the bootstrap kite method.
type BootstrapRequest struct {
	Provider string `json:"provider"`

	// Identifiers contains identifers to be used with terraform
	Identifiers []string `json:"identifiers"`

	GroupName string `json:"groupName"`

	// Destroy destroys the bootstrap resource associated with the given
	// identifiers
	Destroy bool
}

// Valid implements the Validator interface.
func (req *BootstrapRequest) Valid() error {
	if len(req.Identifiers) == 0 {
		return errors.New("identifiers are not passed")
	}
	if req.GroupName == "" {
		return errors.New("group name is not passed")
	}
	return nil
}

// Bootstrap provides bootstrap as a kite method.
func (k *Kloud) Bootstrap(r *kite.Request) (interface{}, error) {
	return k.stackMethod(r, Stacker.HandleBootstrap)
}

/// PLAN

// PlanRequest represents an argument of the plan kite method.
type PlanRequest struct {
	Provider        string `json:"provider"`
	StackTemplateID string `json:"stackTemplateId"`
	GroupName       string `json:"groupName"`
}

// PlanResponse represents a reponse type of the plan kite method.
type PlanResponse struct {
	Machines interface{} `json:"machines"`
}

// Valid implements the Validator interface.
func (req *PlanRequest) Valid() error {
	if req.StackTemplateID == "" {
		return errors.New("stackIdTemplate is not passed")
	}
	if req.GroupName == "" {
		return errors.New("group name is not passed")
	}
	return nil
}

// Plan provides plan as a kite method.
func (k *Kloud) Plan(r *kite.Request) (interface{}, error) {
	return k.stackMethod(r, Stacker.HandlePlan)
}

/// STATUS

// StatusRequest represents an argument of status kite method.
type StatusRequest struct {
	StackID string `json:"stackId"`
}

// Valid implements the Validator interface.
func (req *StatusRequest) Valid() error {
	if req.StackID == "" {
		return errors.New("stackId is not passed")
	}
	return nil
}

// StatusResponse represents a response of status kite method.
type StatusResponse struct {
	StackID    string    `json:"stackId"`
	Status     string    `json:"status"`
	ModifiedAt time.Time `json:"modifiedAt"`
}

// Status
//
// Status method is provider-agnostic.
func (k *Kloud) Status(r *kite.Request) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var arg StatusRequest
	if err := r.Args.One().Unmarshal(&arg); err != nil {
		return nil, err
	}
	if err := arg.Valid(); err != nil {
		return nil, err
	}

	var resp *StatusResponse
	switch v, err := k.statusCache.Get(arg.StackID); {
	case err == cache.ErrNotFound:
		// TODO(rjeczalik): fetch only status
		computeStack, err := modelhelper.GetComputeStack(arg.StackID)
		if err != nil {
			return nil, err
		}

		resp = &StatusResponse{
			StackID:    arg.StackID,
			Status:     computeStack.Status.State,
			ModifiedAt: computeStack.Status.ModifiedAt,
		}

		k.statusCache.Set(arg.StackID, resp)
	case err != nil:
		return nil, err
	default:
		resp = v.(*StatusResponse)
	}

	return resp, nil
}
