package stack

import (
	"errors"
	"koding/kites/config"

	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/eventer"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

var Konfig = &config.Konfig{} // initialized in main by koding/kites/kloud/kloud

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

// StackFunc handles execution of a single team method.
type StackFunc func(Stacker, context.Context) (interface{}, error)

func IsKloudSecretAuth(r *kite.Request, key string) bool {
	return key != "" && r.Auth != nil && r.Auth.Type == "kloudSecret" && r.Auth.Key == key
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

	if IsKloudSecretAuth(r, k.SecretKey) {
		// kloudctl is not authenticated with username, let it overwrite it
		r.Username = args.Impersonate
	}

	k.Log.Debug("Called %q by %q with %q", r.Method, r.Username, r.Args.Raw)

	if args.GroupName == "" {
		args.GroupName = "koding"
	}

	s, ctx, err := k.newStack(r, &args)
	if err != nil {
		return nil, err
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
	//  - plan errors due to invalud user input
	if err != nil {
		if _, ok := err.(*Error); ok {
			k.Log.Warning("%s (method=%s, user=%s, group=%s)", err, r.Method, r.Username, args.GroupName)
		} else {
			k.Log.Debug("method %q for user %q failed: %s", r.Method, r.Username, err)
		}

		// ensure UI receives proper error origin - kloudError
		if _, ok := err.(*kite.Error); !ok {
			err = NewErrorMessage(err.Error())
		}
	}

	k.send(ctx)

	return resp, err
}

func (k *Kloud) newStack(r *kite.Request, req *TeamRequest) (Stacker, context.Context, error) {
	if k.NewStack != nil {
		return k.NewStack(r, req)
	}

	p, ok := k.providers[req.Provider]
	if !ok {
		return nil, nil, NewError(ErrProviderNotFound)
	}
	// Build context value.
	ctx := request.NewContext(context.Background(), r)
	ctx = context.WithValue(ctx, TeamRequestKey, req)
	if k.PublicKeys != nil {
		ctx = publickeys.NewContext(ctx, k.PublicKeys)
	}

	if k.ContextCreator != nil {
		ctx = k.ContextCreator(ctx)
	}

	if req.StackID != "" {
		evID := r.Method + "-" + req.StackID
		ctx = eventer.NewContext(ctx, k.NewEventer(evID))

		k.Log.Debug("Eventer created %q", evID)
	} else if req.Identifier != "" {
		evID := r.Method + "-" + req.GroupName + "-" + req.Identifier
		ctx = eventer.NewContext(ctx, k.NewEventer(evID))

		k.Log.Debug("Eventer created %q", evID)
	}

	if req.Debug {
		ctx = k.setTraceID(r.Username, r.Method, ctx)
	}

	// Create stack handler.
	v, err := p.Stack(ctx)
	if err != nil {
		return nil, nil, errors.New("error creating stack: " + err.Error())
	}

	s, ok := v.(Stacker)
	if !ok {
		return nil, nil, NewError(ErrStackNotImplemented)
	}

	return s, ctx, nil
}
