package session

import (
	"koding/db/mongodb"
	"koding/kites/kloud/api/amazon"
	"koding/kites/kloud/api/sl"
	"koding/kites/kloud/dnsstorage"
	"koding/kites/kloud/eventer"
	"koding/kites/kloud/pkg/dnsclient"
	"koding/kites/kloud/terraformer"
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
	Userdata   *userdata.Userdata
	Log        logging.Logger

	// AWS
	AWSClient  *amazon.Amazon
	AWSClients *amazon.Clients

	// Terraformer
	//
	// TODO(rjeczalik): Connect to terraformer once and use
	// single connection instead of connecting for each
	// request.
	Terraformer *terraformer.Options

	// Softlayer
	SLClient *sl.Softlayer
}

func FromContext(ctx context.Context) (*Session, bool) {
	c, ok := ctx.Value(sessionKey).(*Session)
	return c, ok
}

func NewContext(ctx context.Context, session *Session) context.Context {
	return context.WithValue(ctx, sessionKey, session)
}
