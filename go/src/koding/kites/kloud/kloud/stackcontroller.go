package kloud

import (
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/eventer"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

// GroupNameKey is used to pass group name to stack handler.
var GroupNameKey struct {
	byte `key:"groupName"`
}

// Stacker is a provider-specific handler that implements team methods.
type Stacker interface {
	Apply(context.Context) (interface{}, error)
	Authenticate(context.Context) (interface{}, error)
	Bootstrap(context.Context) (interface{}, error)
	Plan(context.Context) (interface{}, error)
}

// StackProvider is responsible for creating stack providers.
type StackProvider interface {
	Stack(ctx context.Context) (Stacker, error)
}

// StackFunc handles execution of a single team method.
type StackFunc func(Stacker, context.Context) (interface{}, error)

// stackMethod
func (k *Kloud) stackMethod(r *kite.Request, fn StackFunc) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	k.Log.Warning("Called %s with %q", r.Method, r.Args.Raw)

	var argCommon struct {
		Provider  string `json:"provider"`
		StackID   string `json:"stackId,omitempty"`
		GroupName string `json:"groupName,omitempty"`
	}

	// Unamrshal common arguments.
	if err := r.Args.One().Unmarshal(&argCommon); err != nil {
		return nil, err
	}

	// TODO(rjeczalik): compatibility code, remove
	if argCommon.Provider == "" {
		argCommon.Provider = "aws"
	}

	groupName := argCommon.GroupName
	if groupName == "" {
		groupName = "koding"
	}

	p, ok := k.providers[argCommon.Provider].(StackProvider)
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	// Build context value.
	ctx := request.NewContext(context.Background(), r)
	ctx = context.WithValue(ctx, GroupNameKey, groupName)
	if k.PublicKeys != nil {
		ctx = publickeys.NewContext(ctx, k.PublicKeys)
	}
	if k.ContextCreator != nil {
		ctx = k.ContextCreator(ctx)
	}
	if argCommon.StackID != "" {
		evID := r.Method + "-" + argCommon.StackID
		ctx = eventer.NewContext(ctx, k.NewEventer(evID))
	}

	// Create stack handler.
	s, err := p.Stack(ctx)
	if err != nil {
		return nil, err
	}

	// Currently only apply method is asynchronous, rest
	// of the is sync. That's why the fn execution is synchronous here,
	// and the fn itself emits events if needed.
	//
	// This differs from k.coreMethods.
	resp, err := fn(s, ctx)

	// Do not log error in production as most of them are expected:
	//
	//  - authenticate errors due to invalid credentials
	//  - plan errors due to invalud user input
	//
	// TODO(rjeczalik): Refactor errors so the user-originated have different
	// type and log unexpected errors with k.Log.Error().
	if err != nil {
		k.Log.Debug("method %q for user %q failed: %s", r.Method, r.Username, err)
	}

	return resp, err
}
