package pubnub

import (
	"errors"
	"sync"

	"github.com/pubnub/go/messaging"
)

var ErrInvalidType = errors.New("invalid type")

type AccessGrant struct {
	pool sync.Pool
}

type AccessGrantOptions struct {
	ResumeOnReconnect bool
	SubscribeTimeout  int
	Origin            string
}

func NewAccessGrantOptions() *AccessGrantOptions {
	return &AccessGrantOptions{
		ResumeOnReconnect: true,
		SubscribeTimeout:  20,
		Origin:            "pubsub.pubnub.com",
	}
}

func NewAccessGrant(ao *AccessGrantOptions, cs *ClientSettings) *AccessGrant {
	messaging.SetResumeOnReconnect(ao.ResumeOnReconnect)
	messaging.SetSubscribeTimeout(uint16(ao.SubscribeTimeout))
	messaging.SetOrigin(ao.Origin)

	p := sync.Pool{
		New: func() interface{} {
			return NewPubNubClient(cs)
		},
	}

	return &AccessGrant{pool: p}
}

func (ag *AccessGrant) Grant(as *AuthSettings) error {
	client, ok := ag.pool.Get().(*PubNubClient)
	if !ok {
		panic(ErrInvalidType)
	}

	defer ag.pool.Put(client)

	client.pub.SetAuthenticationKey(as.Token)

	return client.Grant(as)
}
