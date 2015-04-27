package session

import (
	"koding/db/mongodb"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/pkg/multiec2"
	"koding/kites/kloud/userdata"

	"github.com/koding/kite"
	"github.com/koding/logging"
	"golang.org/x/net/context"
)

type key int

const sessionKey key = 0

type Session struct {
	DB         *mongodb.MongoDB
	Kite       *kite.Kite
	DNSClient  dnsclient.Client
	DNSStorage dnsstorage.Storage
	Eventer    eventer.Eventer
	AWSClient  *amazon.Amazon
	AWSClients *multiec2.Clients
	Userdata   *userdata.Userdata
	Log        logging.Logger
}

func FromContext(ctx context.Context) (*Session, bool) {
	c, ok := ctx.Value(sessionKey).(*Session)
	return c, ok
}

func NewContext(ctx context.Context, session *Session) context.Context {
	return context.WithValue(ctx, sessionKey, session)
}
