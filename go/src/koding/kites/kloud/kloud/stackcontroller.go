package kloud

import (
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/eventer"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

// LogNameKey is used to pass logging context name to stack handler.
var LogNameKey struct {
	byte `key:"logName"`
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

	k.Log.Debug("Called %s with %q", r.Method, r.Args.Raw)

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

	// Context name for stack logging.
	logName := argCommon.GroupName
	if logName != "" {
		logName = argCommon.StackID
	}

	p, ok := k.providers[argCommon.Provider].(StackProvider)
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	// Build context value.
	ctx := request.NewContext(context.Background(), r)
	ctx = context.WithValue(ctx, LogNameKey, logName)
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
	return fn(s, ctx)
}
