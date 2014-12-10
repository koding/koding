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
	pub := messaging.NewPubnub(conf.PublishKey, conf.SubscribeKey, "", "", false, "")
	pb := &Pubnub{
		pub:       pub,
		log:       log,
		successCh: make(chan []byte),
		errorCh:   make(chan []byte),
	}

	go pb.handleResponse()

	return pb
}

func (p *Pubnub) Authenticate(req *ChannelRequest) error {
	return nil
}

func (p *Pubnub) Push(pm *PushMessage) {
	channelName := prepareChannelName(pm)
	p.pub.Publish(channelName, pm, p.successCh, p.errorCh)
}

func (p *Pubnub) Close() {
	p.pub.CloseExistingConnection()
}

func (p *Pubnub) UpdateInstance(um *UpdateInstanceMessage) {
}
func prepareChannelName(pm *PushMessage) string {
	return fmt.Sprintf("%s-%s-%s-%s", pm.Token, pm.Channel.Group, pm.Channel.Type, pm.Channel.Name)
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
