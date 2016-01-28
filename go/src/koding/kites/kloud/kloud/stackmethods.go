package kloud

import (
	"errors"
	"time"

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

/// APPLY

// ApplyRequest
type ApplyRequest struct {
	Provider  string `json:"provider"`
	StackID   string `json:"stackId"`
	GroupName string `json:"groupName"`

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

// Apply
func (k *Kloud) Apply(r *kite.Request) (interface{}, error) {
	return k.stackMethod(r, Stacker.Apply)
}

/// AUTHENTICATE

// AuthenticateRequest
type AuthenticateRequest struct {
	Provider string `json:"provider"`
	// Identifiers contains identifiers to be authenticated
	Identifiers []string `json:"identifiers"`

	GroupName string `json:"groupName"`
}

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

// Authenticate
func (k *Kloud) Authenticate(r *kite.Request) (interface{}, error) {
	return k.stackMethod(r, Stacker.Authenticate)
}

/// BOOTSTRAP

// BootstrapRequest
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

// Bootstrap
func (k *Kloud) Bootstrap(r *kite.Request) (interface{}, error) {
	return k.stackMethod(r, Stacker.Bootstrap)
}

/// PLAN

// PlanRequest
type PlanRequest struct {
	Provider        string `json:"provider"`
	StackTemplateID string `json:"stackTemplateId"`
	GroupName       string `json:"groupName"`
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

// Plan
func (k *Kloud) Plan(r *kite.Request) (interface{}, error) {
	return k.stackMethod(r, Stacker.Plan)
}

/// STATUS

// StatusRequest
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

// StatusResponse
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
