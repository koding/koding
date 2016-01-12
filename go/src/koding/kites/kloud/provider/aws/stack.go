package awsprovider

import (
	"errors"
	"koding/kites/kloud/contexthelper/publickeys"
	"koding/kites/kloud/contexthelper/request"
	"koding/kites/kloud/contexthelper/session"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/kloud"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
)

// Stack
type Stack struct {
	Log logging.Logger
	Req *kite.Request

	Session *session.Session
	Keys    *publickeys.Keys
	Eventer eventer.Eventer
}

// Ensure Provider implements the kloud.StackProvider interface.
var _ kloud.StackProvider = (*Provider)(nil)

// Stack
func (p *Provider) Stack(ctx context.Context) (kloud.Stacker, error) {
	var s Stack

	var ok bool
	if s.Req, ok = request.FromContext(ctx); !ok {
		return nil, errors.New("request not available in context")
	}

	if s.Session, ok = session.FromContext(ctx); !ok {
		return nil, errors.New("session not available in context")
	}

	if logName, ok := ctx.Value(kloud.LogNameKey).(string); ok {
		s.Log = p.Log.New(logName)
	} else {
		s.Log = p.Log
	}

	if keys, ok := publickeys.FromContext(ctx); ok {
		s.Keys = keys
	}

	if ev, ok := eventer.FromContext(ctx); ok {
		s.Eventer = ev
	}

	return &s, nil
}
