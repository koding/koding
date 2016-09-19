package stack

import (
	"errors"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/eventer"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

type TeamRequest struct {
	Provider    string `json:"provider"`
	StackID     string `json:"stackId,omitempty"`
	GroupName   string `json:"groupName,omitempty"`
	Debug       bool   `json:"debug,omitempty"`
	Impersonate string `json:"impersonate,omitempty"` // only for kloudctl
	Identifier  string `json:"identifier"`
}

func (req *TeamRequest) metricTags() []string {
	var tags []string

	if req.Provider != "" {
		tags = append(tags, "provider:"+req.Provider)
	}

	if req.GroupName != "" {
		tags = append(tags, "team:"+req.GroupName)
	}

	return tags
}

// TeamRequestKey is used to pass group name to stack handler.
var TeamRequestKey struct {
	byte `key:"teamRequest"`
}

func TeamRequestFromContext(ctx context.Context) (*TeamRequest, bool) {
	req, ok := ctx.Value(TeamRequestKey).(*TeamRequest)
	return req, ok
}

// Migrater provides an interface to import solo machine (from "koding"
// provider) to the specific stack provider.
type Migrater interface {
	Migrate(context.Context) (interface{}, error)
}

// StackFunc handles execution of a single team method.
type StackFunc func(Stack, context.Context) (interface{}, error)

func IsKloudctlAuth(r *kite.Request, key string) bool {
	return key != "" && r.Auth != nil && r.Auth.Type == "kloudctl" && r.Auth.Key == key
}

// stackMethod routes the team method call to a requested provider.
func (k *Kloud) stackMethod(r *kite.Request, fn StackFunc) (interface{}, error) {
	if r.Args == nil {
		return nil, NewError(ErrNoArguments)
	}

	var args TeamRequest

	// Unamrshal common arguments.
	if err := r.Args.One().Unmarshal(&args); err != nil {
		return nil, errors.New("invalid request: " + err.Error())
	}

	// TODO(rjeczalik): compatibility code, remove
	if args.Provider == "" {
		args.Provider = "aws"
	}

	if IsKloudctlAuth(r, k.SecretKey) {
		// kloudctl is not authenticated with username, let it overwrite it
		r.Username = args.Impersonate
	}

	k.Log.Debug("Called %q by %q with %q", r.Method, r.Username, r.Args.Raw)

	if args.GroupName == "" {
		args.GroupName = "koding"
	}

	p, ok := k.providers[args.Provider].(Provider)
	if !ok {
		return nil, NewError(ErrProviderNotFound)
	}

	// Build context value.
	ctx := request.NewContext(context.Background(), r)
	ctx = context.WithValue(ctx, TeamRequestKey, &args)
	if k.PublicKeys != nil {
		ctx = publickeys.NewContext(ctx, k.PublicKeys)
	}

	if k.ContextCreator != nil {
		ctx = k.ContextCreator(ctx)
	}

	if args.StackID != "" {
		evID := r.Method + "-" + args.StackID
		ctx = eventer.NewContext(ctx, k.NewEventer(evID))

		k.Log.Debug("Eventer created %q", evID)
	} else if args.Identifier != "" {
		evID := r.Method + "-" + args.GroupName + "-" + args.Identifier
		ctx = eventer.NewContext(ctx, k.NewEventer(evID))

		k.Log.Debug("Eventer created %q", evID)
	}

	if args.Debug {
		ctx = k.setTraceID(r.Username, r.Method, ctx)
	}

	// Create stack handler.
	s, err := p.Stack(ctx)
	if err != nil {
		return nil, errors.New("error creating stack: " + err.Error())
	}

	ctx = k.traceRequest(ctx, args.metricTags())

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

		// ensure UI receives proper error origin - kloudError
		if _, ok := err.(*kite.Error); !ok {
			err = NewErrorMessage(err.Error())
		}
	}

	k.send(ctx)

	return resp, err
}
