package models

import (
	"fmt"
	"socialapi/config"

	"github.com/koding/logging"
	"github.com/pubnub/go/messaging"
)

type Pubnub struct {
	pub       *messaging.Pubnub
	successCh chan []byte
	errorCh   chan []byte
	log       logging.Logger
}

const Origin = "pubsub.pubnub.com"

func NewPubnub(conf config.Pubnub, log logging.Logger) *Pubnub {
	messaging.SetResumeOnReconnect(false)
	messaging.SetSubscribeTimeout(3)
	messaging.LoggingEnabled(true)
	messaging.SetOrigin(Origin)
	// publishKey, subscribeKey, secretKey, cipher, ssl, uuid
	pub := messaging.NewPubnub(conf.PublishKey, conf.SubscribeKey, conf.SecretKey, "", false, "")
	pb := &Pubnub{
		pub:       pub,
		log:       log,
		successCh: make(chan []byte),
		errorCh:   make(chan []byte),
	}

	go pb.handleResponse()

	return pb
}

func (p *Pubnub) Push(pm *PushMessage) error {
	channelName := prepareChannelName(pm)

	return p.publish(channelName, pm)
}

func (p *Pubnub) Close() {
	p.pub.CloseExistingConnection()
	close(p.successCh)
	close(p.errorCh)
}

func (p *Pubnub) UpdateInstance(um *UpdateInstanceMessage) error {
	channelName := prepareInstanceChannelName(um)

	return p.publish(channelName, um)
}

func (p *Pubnub) NotifyUser(nm *NotificationMessage) error {
	channelName := prepareNotificationChannelName(nm)

	return p.publish(channelName, nm)
}

	p.pub.Publish(channelName, message, p.successCh, p.errorCh)
func (p *Pubnub) publish(channelName string, message interface{}) error {
}

func prepareChannelName(pm *PushMessage) string {
	return fmt.Sprintf("channel-%s-%s-%s-%s", pm.Token, pm.Channel.Group, pm.Channel.Type, pm.Channel.Name)
}

func prepareInstanceChannelName(um *UpdateInstanceMessage) string {
	return fmt.Sprintf("instance-%s", um.Token)
}

func prepareNotificationChannelName(nm *NotificationMessage) string {
	return fmt.Sprintf("notification-%s", nm.Nickname)
}

func (p *Pubnub) handleResponse() {
	for {
		select {
		case success := <-p.successCh:
			if string(success) != "[]" {
				p.log.Debug("Response: %s ", success)
			}
		case failure := <-p.errorCh:
			if string(failure) != "[]" {
				p.log.Error("Could not push message to pubnub: %s", failure)
			}
		}
	}
}
