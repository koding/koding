package models

import (
	"socialapi/config"
	"strconv"
	"time"

	"github.com/koding/logging"
	"github.com/koding/pubnub"
)

type PubNub struct {
	pub   *pubnub.PubNubClient
	grant *pubnub.AccessGrant
	log   logging.Logger
	token string
}

const (
	PublishTimeout = 3 * time.Second
	ServerId       = -1
)

func NewPubNub(conf config.Pubnub, log logging.Logger) *PubNub {

	cs := NewClientSettings(conf)
	cs.ID = strconv.Itoa(ServerId)
	cs.Token = conf.ServerAuthKey
	client := pubnub.NewPubNubClient(cs)

	// when secretkey is used all the messages are signed.
	// we only need to sign grant access messages
	cs.SecretKey = conf.SecretKey
	ag := pubnub.NewAccessGrant(pubnub.NewAccessGrantOptions(), cs)

	pb := &PubNub{
		pub:   client,
		grant: ag,
		log:   log,
		token: conf.ServerAuthKey,
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

	pm.Channel.SecretNames = []string{}

	// TODO channel access must be granted with channel creation
	// channel grant public access for public channels
	typeConstant := pmc.Type
	if typeConstant == "privatemessage" || typeConstant == "pinnedactivity" {
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

func (p *PubNub) grantServerAccess(c ChannelInterface) error {
	a := &Authenticate{
		Account: &Account{Id: ServerId, Token: p.token},
		Channel: c,
	}

	return p.GrantAccess(a, c)
}

func (p *PubNub) Close() {
	p.pub.Close()
}

func (p *PubNub) UpdateInstance(um *UpdateInstanceMessage) error {
	mc := NewMessageUpdateChannel(*um)

	// TODO grant access when the message is created instead of here
	if err := p.GrantPublicAccess(mc); err != nil {
		return err
	}

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
func (p *PubNub) GrantAccess(a *Authenticate, c ChannelInterface) error {
	// read and write access can be optional later on.
	settings := &pubnub.AuthSettings{
		ChannelName: c.PrepareName(),
		CanRead:     true,
		CanWrite:    true,
		TTL:         0,
		Token:       a.Account.Token,
	}

	return p.grant.Grant(settings)
}

	// read and write access can be optional later on.

}

func (p *PubNub) GrantPublicAccess(c ChannelInterface) error {
	a := &Authenticate{}
	a.Account = &Account{Token: ""}

	return p.GrantAccess(a, c)
}

func (p *PubNub) publish(c ChannelInterface, message interface{}) error {
	return p.pub.Push(c.PrepareName(), message)
}
