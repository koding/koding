package models

import (
	"fmt"
	"socialapi/config"
	"strconv"
	"time"

	"github.com/koding/logging"
	"github.com/pubnub/go/messaging"
)

type Pubnub struct {
	pub   *messaging.Pubnub
	log   logging.Logger
	token string
}

const (
	PublishTimeout = 3 * time.Second
	ServerId       = -1
)

func NewPubnub(conf config.Pubnub, log logging.Logger) *Pubnub {
	messaging.SetResumeOnReconnect(true)
	messaging.SetSubscribeTimeout(3)
	messaging.LoggingEnabled(true)
	messaging.SetOrigin(conf.Origin)

	// TODO we can use different pubnub connections for channel access grants and message publish
	// library is signing all the messages which is not needed
	// publishKey, subscribeKey, secretKey, cipher, ssl, uuid
	pub := messaging.NewPubnub(conf.PublishKey, conf.SubscribeKey, conf.SecretKey, "", false, strconv.Itoa(ServerId))
	pub.SetAuthenticationKey(conf.ServerAuthKey)

	pb := &Pubnub{
		pub:   pub,
		log:   log,
		token: conf.ServerAuthKey,
	}

	return pb
}

func (p *Pubnub) Push(pm *PushMessage) error {
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

func (p *Pubnub) grantServerAccess(c ChannelInterface) error {
	a := &Authenticate{
		Account: &Account{Id: ServerId, Token: p.token},
		Channel: c,
	}

	return p.GrantAccess(a, c)
}

func (p *Pubnub) Close() {
	p.pub.CloseExistingConnection()
}

func (p *Pubnub) UpdateInstance(um *UpdateInstanceMessage) error {
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

func (p *Pubnub) NotifyUser(nm *NotificationMessage) error {
	nc := NewNotificationChannel(nm.Account)
	// TODO grant access when the account is created
	if err := p.grantServerAccess(nc); err != nil {
		return err
	}

	return p.publish(nc, nm)
}

func (p *Pubnub) Authenticate(a *Authenticate) error {
	return a.Channel.GrantAccess(p, a)
}

// GrantAcess grants access for the channel with the given token. When token value is an
// empty string it provides public access for the channel.
// TODO by default TTL is set to 0. Add TTL support later on
func (p *Pubnub) GrantAccess(a *Authenticate, c ChannelInterface) error {
	pr := NewPubnubRequest()
	pr.log = p.log
	channelName := c.PrepareName()

	go pr.handlePublishResponse()
	// read and write access can be optional later on.
	// channel name, token, read access, write access, TTL, success channel, error channel
	go p.pub.GrantSubscribe(channelName, a.Account.Token, true, true, 0, pr.successCh, pr.errorCh)

	return <-pr.done
}

func (p *Pubnub) GrantPublicAccess(c ChannelInterface) error {
	a := &Authenticate{}
	a.Account = &Account{Token: ""}

	return p.GrantAccess(a, c)
}

func (p *Pubnub) publish(c ChannelInterface, message interface{}) error {

	pr := NewPubnubRequest()
	pr.log = p.log

	go pr.handlePublishResponse()

	go p.pub.Publish(c.PrepareName(), message, pr.successCh, pr.errorCh)

	return <-pr.done
}

/////////////////// PubnubRequest /////////////////////

type PubnubRequest struct {
	successCh chan []byte
	errorCh   chan []byte
	done      chan error
	log       logging.Logger
}

func NewPubnubRequest() *PubnubRequest {
	return &PubnubRequest{
		successCh: make(chan []byte),
		errorCh:   make(chan []byte),
		done:      make(chan error),
	}
}

func (pr *PubnubRequest) handlePublishResponse() {
	for {
		select {
		case <-pr.successCh:
			pr.done <- nil
			return
		case failure := <-pr.errorCh:
			// TODO fix error response
			pr.log.Error("Could not push message to pubnub: %v", string(failure))
			return
		case <-time.After(PublishTimeout):
			pr.done <- fmt.Errorf("pubnub timeout")
		}
	}
}
