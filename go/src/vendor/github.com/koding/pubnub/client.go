package pubnub

import (
	"errors"
	"sync"

	"github.com/pubnub/go/messaging"
)

var (
	ErrChannelNotSet    = errors.New("channel name is not set")
	ErrTimeout          = errors.New("timeout reached")
	ErrConnectionAbort  = errors.New("connection aborted")
	ErrConnectionClosed = errors.New("connection closed")
)

type PubNubClient struct {
	pub      *messaging.Pubnub
	channels map[string]*Channel
	mu       sync.RWMutex
	closed   bool
}

func NewPubNubClient(cs *ClientSettings) *PubNubClient {
	pub := messaging.NewPubnub(cs.PublishKey, cs.SubscribeKey, cs.SecretKey, cs.Cipher, cs.SSL, cs.ID, nil)
	return &PubNubClient{
		pub:      pub,
		channels: make(map[string]*Channel),
	}
}

////////////// ClientSettings ////////////////////

type ClientSettings struct {
	PublishKey   string
	SubscribeKey string
	SecretKey    string
	Cipher       string
	SSL          bool
	ID           string
}

// Push sends a message to the channel with channelName. If Access Manager is enabled
// access must be granted first.
func (p *PubNubClient) Push(channelName string, body interface{}) error {
	if p.closed {
		return ErrConnectionClosed
	}

	pr := NewPubNubRequest(channelName, nil, nil)
	defer pr.Close()

	go pr.handleResponse()

	go p.pub.Publish(channelName, body, pr.successCh, pr.errorCh)

	return pr.Do()
}

// Grant read/write access to the given token for TTL period. If token
func (p *PubNubClient) Grant(a *AuthSettings) error {
	if p.closed {
		return ErrConnectionClosed
	}

	if a.ChannelName == "" {
		return ErrChannelNotSet
	}

	pr := NewPubNubRequest(a.ChannelName, nil, nil)
	defer pr.Close()

	p.pub.SetAuthenticationKey(a.Token)

	go pr.handleResponse()

	// channel name, read access, write access, TTL, success channel, error channel
	go p.pub.GrantSubscribe(a.ChannelName, a.CanRead, a.CanWrite, a.TTL, a.Token, pr.successCh, pr.errorCh)

	return pr.Do()
}

// Subscribe to given channel.
// Returns a message listener channel
// TODO add support for multiple channel subscription
func (p *PubNubClient) Subscribe(channelName string) (*Channel, error) {
	if p.closed {
		return nil, ErrConnectionClosed
	}

	if channelName == "" {
		return nil, ErrChannelNotSet
	}

	return p.fetchOrCreateChannel(channelName)
}

func (p *PubNubClient) Close() {
	p.pub.CloseExistingConnection()

	for _, channel := range p.channels {
		channel.Close()
	}

	p.closed = true
}

func (p *PubNubClient) SetAuthToken(token string) {
	p.pub.SetAuthenticationKey(token)
}

func (p *PubNubClient) fetchOrCreateChannel(channelName string) (*Channel, error) {
	p.mu.RLock()
	channel, ok := p.channels[channelName]
	p.mu.RUnlock()
	if ok {
		return channel, nil
	}

	channel, err := p.NewChannel(channelName)
	if err != nil {
		return nil, err
	}

	p.mu.Lock()

	p.channels[channelName] = channel

	p.mu.Unlock()

	return channel, nil
}

//////////////////// PubnubAuthSettings /////////////////////

type AuthSettings struct {

	// PubNub channel name
	ChannelName string

	// Grant access for the token. When token is an
	// empty string it provides public access for the channel.
	Token string

	// Grant read access
	CanRead bool

	// Grant write Access
	CanWrite bool

	// Time to live value in minutes.
	// Access is revoked after TTL period
	// Min-max values can be consecutively: 1 and 525600
	// 0 value will grant access indefinitely
	// -1 causes default value (1440) to be set
	TTL int
}
