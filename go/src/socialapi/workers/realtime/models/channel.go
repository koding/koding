package models

import (
	"fmt"
	"socialapi/config"
	socialapimodels "socialapi/models"
)

type Channel struct {
	Id          int64    `json:"id,string"`
	Name        string   `json:"name"`
	Type        string   `json:"typeConstant"`
	Group       string   `json:"groupName"`
	SecretNames []string `json:"secretNames"`
	Token       string   `json:"token"`
}

func (c *Channel) IsPrivateChannel() bool {
	if c.Group != socialapimodels.Channel_KODING_NAME {
		return true
	}

	return c.Type == "privatemessage" ||
		c.Type == "pinnedactivity" ||
		c.Type == "collaboration" ||
		c.Type == "bot"
}

type ChannelManager interface {
	PrepareName() string
	GrantAccess(p *PubNub, a *Authenticate) error
}

////////// PrivateMessageChannel //////////

// TODO change its name
type PrivateMessageChannel struct {
	Channel
}

func NewPrivateMessageChannel(c Channel) *PrivateMessageChannel {
	return &PrivateMessageChannel{c}
}

func (pmc *PrivateMessageChannel) PrepareName() string {
	return fmt.Sprintf("channel-%s", pmc.Token)
}

func (pmc *PrivateMessageChannel) GrantAccess(p *PubNub, a *Authenticate) error {
	if pmc.IsPrivateChannel() {
		return p.GrantAccess(a, pmc)
	}

	return p.GrantPublicAccess(pmc)
}

////////// NotificationChannel //////////

type NotificationChannel struct {
	Account *socialapimodels.Account
}

func NewNotificationChannel(a *socialapimodels.Account) *NotificationChannel {
	return &NotificationChannel{
		Account: a,
	}
}

func (nc *NotificationChannel) PrepareName() string {
	env := config.MustGet().Environment
	return fmt.Sprintf("notification-%s-%s", env, nc.Account.Nick)
}

func (nc *NotificationChannel) GrantAccess(p *PubNub, a *Authenticate) error {
	return p.GrantAccess(a, nc)
}

////////// MessageUpdateChannel //////////

type MessageUpdateChannel struct {
	UpdateInstanceMessage
}

func NewMessageUpdateChannel(ui UpdateInstanceMessage) *MessageUpdateChannel {
	return &MessageUpdateChannel{ui}
}

func (mc *MessageUpdateChannel) PrepareName() string {
	// Send message instance events to parent channel itself.
	return fmt.Sprintf("channel-%s", mc.ChannelToken)
}

func (mc *MessageUpdateChannel) GrantAccess(p *PubNub, a *Authenticate) error {
	return p.GrantPublicAccess(mc)
}
