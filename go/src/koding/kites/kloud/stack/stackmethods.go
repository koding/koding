package stack

import (
	"errors"
	"time"

	"golang.org/x/net/context"

	"koding/db/mongodb/modelhelper"

	"github.com/koding/cache"
	"github.com/koding/kite"
)

// Validator validates and returns non-nil error when it's ill-formed.
//
// For use with model, request and response structs.
type Validator interface {
	Valid() error
}

/// MIGRATE

// MigrateRequest represents an argument of the migrate kite method.
type MigrateRequest struct {
	Provider   string   `json:"provider"`
	Machines   []string `json:"machines"`
	Identifier string   `json:"identifier"`
	GroupName  string   `json:"groupName"`
	StackName  string   `json:"stackName"`
}

// Validate implements the kloud.Validator interface.
func (req *MigrateRequest) Valid() error {
	if len(req.Machines) == 0 {
		return errors.New("machine list is empty")
	}

	if req.Identifier == "" {
		return errors.New("identifier is empty")
	}

	if req.GroupName == "" {
		return errors.New("groupName is empty")
	}

	if req.StackName == "" {
		req.StackName = "Migrated Stack Template"
	}

	return nil
}

// Migrater provides migrate as kite method.
//
// If the requested provider does not implement the Migrater interface,
// the method return with a ErrProviderNotImplemented error.
func (k *Kloud) Migrate(r *kite.Request) (interface{}, error) {
	fn := func(s Stack, ctx context.Context) (interface{}, error) {
		m, ok := s.(Migrater)
		if !ok {
			return nil, NewError(ErrProviderNotImplemented)
		}

		return m.Migrate(ctx)
	}

	return k.stackMethod(r, fn)
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
	return k.stackMethod(r, Stack.Apply)
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
	return k.stackMethod(r, Stack.Authenticate)
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
	return k.stackMethod(r, Stack.Bootstrap)
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
	return k.stackMethod(r, Stack.Plan)
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
