package provider

import (
	"errors"

	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/stack"
	"koding/kites/kloud/stackplan"

	"github.com/hashicorp/terraform/terraform"
	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
)

// BaseStack provides shared implementation of team handler for use
// with external provider-specific handlers.
type BaseStack struct {
	Log     logging.Logger
	Req     *kite.Request
	Builder *stackplan.Builder
	Session *session.Session

	// Resource callbacks - called during building stack definition
	// for apply operations.
	//
	// TODO(rjeczalik): Create stackplan.ResourceBuilder interface and move all
	// provider/* to stackplan.Builder in order to support multiple providers
	// per stack.
	BuildResources  func() error
	WaitResources   func(context.Context) error
	UpdateResources func(*terraform.State) error

	// Keys and Eventer may be nil, it depends on the context used
	// to initialize the Stack.
	Keys    *publickeys.Keys
	Eventer eventer.Eventer

	Debug   bool
	TraceID string
}

// NewBaseStack builds new base stack for the given context value.
func (bp *BaseProvider) BaseStack(ctx context.Context) (*BaseStack, error) {
	bs := &BaseStack{}

	var ok bool
	if bs.Req, ok = request.FromContext(ctx); !ok {
		return nil, errors.New("request not available in context")
	}

	req, ok := stack.TeamRequestFromContext(ctx)
	if !ok {
		return nil, errors.New("team request not available in context")
	}

	if bs.Session, ok = session.FromContext(ctx); !ok {
		return nil, errors.New("session not available in context")
	}

	bs.Log = bp.Log.New(req.GroupName)

	if traceID, ok := stack.TraceFromContext(ctx); ok {
		bs.Log = logging.NewCustom("kloud-"+req.Provider, true).New(traceID)
		bs.TraceID = traceID
	}

	if keys, ok := publickeys.FromContext(ctx); ok {
		bs.Keys = keys
	}

	if ev, ok := eventer.FromContext(ctx); ok {
		bs.Eventer = ev
	}

	builderOpts := &stackplan.BuilderOptions{
		Log:       bs.Log.New("stackplan"),
		CredStore: bp.CredStore,
	}

	bs.Builder = stackplan.NewBuilder(builderOpts)

	return bs, nil
}
