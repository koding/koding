package models

import (
	"fmt"
	"socialapi/config"
	socialapimodels "socialapi/models"
	"strconv"
	"sync"
	"time"

	"github.com/cenkalti/backoff"
	"github.com/koding/logging"
	"github.com/koding/pubnub"
)

type PubNub struct {
	pub       *pubnub.PubNubClient
	grant     *pubnub.AccessGrant
	log       logging.Logger
	token     string
	channels  map[string]struct{}
	channelMu sync.RWMutex
}

const (
	PublishTimeout   = 3 * time.Second
	ServerId         = -1
	MaxRetryDuration = 10 * time.Second
)

func NewPubNub(conf config.Pubnub, log logging.Logger) *PubNub {

	cs := NewClientSettings(conf)
	cs.ID = strconv.Itoa(ServerId)
	client := pubnub.NewPubNubClient(cs)
	client.SetAuthToken(conf.ServerAuthKey)

	// when secretkey is used all the messages are signed.
	// we only need to sign grant access messages
	cs.SecretKey = conf.SecretKey
	ag := pubnub.NewAccessGrant(pubnub.NewAccessGrantOptions(), cs)

	pb := &PubNub{
		pub:      client,
		grant:    ag,
		log:      log,
		token:    conf.ServerAuthKey,
		channels: make(map[string]struct{}),
	}

	return pb
}

func NewClientSettings(conf config.Pubnub) *pubnub.ClientSettings {
	return &pubnub.ClientSettings{
		PublishKey:   conf.PublishKey,
		SubscribeKey: conf.SubscribeKey,
	}
}

func (p *PubNub) UpdateChannel(pm *PushMessage) error {
	pmc := NewPrivateMessageChannel(*pm.Channel)

	// channel grant public access for public channels
	if pmc.IsPrivateChannel() {
		// server access must be granted for sending private messages
		if err := p.grantServerAccess(pmc); err != nil {
			return err
		}
	} else {
		if err := p.GrantPublicAccess(pmc); err != nil {
			return err
		}
	}

	return p.publish(pmc, pm)
}

func (p *PubNub) grantServerAccess(c ChannelManager) error {
	ok := p.isAccessGranted(c)
	if ok {
		return nil
	}

	a := &Authenticate{
		Account: &socialapimodels.Account{
			Id:    ServerId,
			Token: p.token,
		},
		Channel: c,
	}

	if err := p.GrantAccess(a, c); err != nil {
		return err
	}

	p.cacheAccessGranted(c)

	return nil
}

func (p *PubNub) isAccessGranted(c ChannelManager) bool {
	p.channelMu.RLock()
	channelName := c.PrepareName()

	_, ok := p.channels[channelName]

	p.channelMu.RUnlock()

	return ok
}

func (p *PubNub) cacheAccessGranted(c ChannelManager) {
	p.channelMu.Lock()
	p.channels[c.PrepareName()] = struct{}{}
	p.channelMu.Unlock()
}

func (p *PubNub) Close() {
	p.pub.Close()
}

func (p *PubNub) UpdateInstance(um *UpdateInstanceMessage) error {
	mc := NewMessageUpdateChannel(*um)

	if err := p.GrantPublicAccess(mc); err != nil {
		return err
	}

	// um.Body is just message data itself in a map. Since we are going
	// to apply the changes via MongoOp in client side, we are sending
	// the changes with '$set' key.
	if um.EventName == "updateInstance" {
		um.Body = map[string]interface{}{"$set": um.Body}
	}

	// Prepend instance id to event name. We are no longer creating a channel
	// for each message by doing this.
	um.EventName = fmt.Sprintf("instance-%s.%s", um.Token, um.EventName)

	if err := p.publish(mc, *um); err != nil {
		p.log.Error("Could not push update instance event: %s", err)
	}

	return nil
}

func (p *PubNub) NotifyUser(nm *NotificationMessage) error {
	nc := NewNotificationChannel(nm.Account)
	// TODO grant access when the account is created
	if err := p.grantServerAccess(nc); err != nil {
		return err
	}

	return p.publish(nc, nm)
}

func (p *PubNub) Authenticate(a *Authenticate) error {
	return a.Channel.GrantAccess(p, a)
}

// GrantAcess grants access for the channel with the given token.
// TODO by default TTL is set to 0. Add TTL support later on
func (p *PubNub) GrantAccess(a *Authenticate, c ChannelManager) error {
	// read and write access can be optional later on.
	settings := &pubnub.AuthSettings{
		ChannelName: c.PrepareName(),
		CanRead:     true,
		CanWrite:    true,
		TTL:         0,
		Token:       a.Account.Token,
	}

	return p.grantAccess(settings)
}

func (p *PubNub) RevokeAccess(a *Authenticate, c ChannelManager) error {
	// read and write access can be optional later on.
	settings := &pubnub.AuthSettings{
		ChannelName: c.PrepareName(),
		CanRead:     false,
		CanWrite:    false,
		TTL:         -1,
		Token:       a.Account.Token,
	}

	return p.grantAccess(settings)
}

func (p *PubNub) GrantPublicAccess(c ChannelManager) error {
	if ok := p.isAccessGranted(c); ok {
		return nil
	}

	a := &Authenticate{}
	a.Account = &socialapimodels.Account{Token: ""}

	if err := p.GrantAccess(a, c); err != nil {
		return err
	}

	p.channels[c.PrepareName()] = struct{}{}

	return nil
}

func (p *PubNub) grantAccess(s *pubnub.AuthSettings) error {
	bo := backoff.NewExponentialBackOff()
	bo.MaxElapsedTime = MaxRetryDuration
	ticker := backoff.NewTicker(bo)

	var err error
	tryCount := 0
	for range ticker.C {
		if err = p.grant.Grant(s); err != nil {
			tryCount++
			p.log.Error("Could not grant access: %s  will retry... (%d time(s))", err, tryCount)
			continue
		}

		ticker.Stop()
	}

	return err
}

func (p *PubNub) publish(c ChannelManager, message interface{}) error {

	bo := backoff.NewExponentialBackOff()
	bo.MaxElapsedTime = MaxRetryDuration
	ticker := backoff.NewTicker(bo)
	defer ticker.Stop()

	var err error
	tryCount := 0
	for range ticker.C {
		if err = p.pub.Push(c.PrepareName(), message); err != nil {
			tryCount++
			p.log.Error("Could not publish message: %s  will retry... (%d time(s))", err, tryCount)

			continue
		}

		ticker.Stop()
	}

	return err
}
