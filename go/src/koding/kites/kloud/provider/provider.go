package provider

import (
	"errors"

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

// BaseStack
type BaseStack struct {
	Log     logging.Logger
	Req     *kite.Request
	Builder *stackplan.Builder
	Session *session.Session

	// Keys and Eventer may be nil, it depends on the context used
	// to initialize the Stack.
	Keys    *publickeys.Keys
	Eventer eventer.Eventer
}

// NewBaseStack
func NewBaseStack(ctx context.Context, log logging.Logger) (*BaseStack, error) {
	bs := &BaseStack{}

	var ok bool
	if bs.Req, ok = request.FromContext(ctx); !ok {
		return nil, errors.New("request not available in context")
	}

	if bs.Session, ok = session.FromContext(ctx); !ok {
		return nil, errors.New("session not available in context")
	}

	if groupName, ok := ctx.Value(kloud.GroupNameKey).(string); ok {
		bs.Log = log.New(groupName)
	} else {
		bs.Log = log
	}

	if keys, ok := publickeys.FromContext(ctx); ok {
		bs.Keys = keys
	}

	if ev, ok := eventer.FromContext(ctx); ok {
		bs.Eventer = ev
	}

	bs.Builder = stackplan.NewBuilder(bs.Log.New("stackplan"))

	return bs, nil

}
