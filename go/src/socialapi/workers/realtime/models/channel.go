package models

import (
	"fmt"
	"socialapi/config"
)

type Channel struct {
	Id          int64    `json:"id,string"`
	Name        string   `json:"name"`
	Type        string   `json:"typeConstant"`
	Group       string   `json:"groupName"`
	SecretNames []string `json:"secretNames"`
	Token       string   `json:"token"`
}

type ChannelInterface interface {
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
	if pmc.Channel.Type == "privatemessage" ||
		pmc.Channel.Type == "pinnedactivity" ||
		pmc.Channel.Type == "collaboration" ||
		pmc.Channel.Type == "bot" {
		return p.GrantAccess(a, pmc)
	}

	return p.GrantPublicAccess(pmc)
}

////////// NotificationChannel //////////

type NotificationChannel struct {
	Account *Account
}

func NewNotificationChannel(a *Account) *NotificationChannel {
	return &NotificationChannel{a}
}

func (nc *NotificationChannel) PrepareName() string {
	env := config.MustGet().Environment
	return fmt.Sprintf("notification-%s-%s", env, nc.Account.Nickname)
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
