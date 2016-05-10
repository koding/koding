package provider

import (
	"errors"

	"koding/kites/common"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"
	"koding/kites/kloud/stackplan"

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

	// Keys and Eventer may be nil, it depends on the context used
	// to initialize the Stack.
	Keys    *publickeys.Keys
	Eventer eventer.Eventer

	TraceID string
}

// NewBaseStack builds new base stack for the given context value.
func (bp *BaseProvider) BaseStack(ctx context.Context) (*BaseStack, error) {
	bs := &BaseStack{}

	var ok bool
	if bs.Req, ok = request.FromContext(ctx); !ok {
		return nil, errors.New("request not available in context")
	}

	req, ok := kloud.TeamRequestFromContext(ctx)
	if !ok {
		return nil, errors.New("team request not available in context")
	}

	if bs.Session, ok = session.FromContext(ctx); !ok {
		return nil, errors.New("session not available in context")
	}

	bs.Log = bp.Log.New(req.GroupName)

	if traceID, ok := kloud.TraceFromContext(ctx); ok {
		bs.Log = common.NewLogger("kloud-"+req.Provider, true).New(traceID)
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
