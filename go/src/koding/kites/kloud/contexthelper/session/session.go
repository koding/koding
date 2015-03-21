package session

import (
	"koding/db/mongodb"
	"koding/kites/kloud/dnsclient"

	"github.com/koding/kite"
	"golang.org/x/net/context"
)

type key int

const sessionKey key = 0

type Session struct {
	DB   *mongodb.MongoDB
	Kite *kite.Kite
	DNS  *dnsclient.DNS
}

func FromContext(ctx context.Context) (*Session, bool) {
	c, ok := ctx.Value(sessionKey).(*Session)
	return c, ok
}

func NewContext(ctx context.Context, session *Session) context.Context {
	return context.WithValue(ctx, sessionKey, session)
}
