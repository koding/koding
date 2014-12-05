package models

import (
	"fmt"
	"socialapi/config"
	"time"

	"github.com/koding/logging"
	"github.com/pubnub/go/messaging"
)

type Pubnub struct {
	pub       *messaging.Pubnub
	successCh chan []byte
	errorCh   chan []byte
	done      chan error
	log       logging.Logger
}

func NewPubnub(conf config.Pubnub, log logging.Logger) *Pubnub {
	messaging.SetResumeOnReconnect(true)
	messaging.SetSubscribeTimeout(3)
	messaging.LoggingEnabled(true)
	messaging.SetOrigin("pubsub.pubnub.com")
	// publishKey, subscribeKey, secretKey, cipher, ssl, uuid
	pub := messaging.NewPubnub(conf.PublishKey, conf.SubscribeKey, "", "", false, "")

	return &Pubnub{
		pub:       pub,
		log:       log,
		successCh: make(chan []byte),
		errorCh:   make(chan []byte),
		done:      make(chan error),
	}
}

func (p *Pubnub) Authenticate(req *ChannelRequest) error {
	return nil
}

func (p *Pubnub) Push(pm *PushMessage) error {
	channelName := prepareChannelName(pm)

	go p.handleResponse()

	go p.pub.Publish(channelName, pm, p.successCh, p.errorCh)

	return <-p.done
}

func (p *Pubnub) Close() {
	p.pub.CloseExistingConnection()
}

func prepareChannelName(pm *PushMessage) string {
	return fmt.Sprintf("%s-%s-%s", pm.Channel.Group, pm.Channel.Type, pm.Channel.Name)
}

func (p *Pubnub) handleResponse() {
	// TODO make it configurable
	timeoutVal := 3 * time.Second
	for {
		select {
		case success := <-p.successCh:
			if string(success) != "[]" {
				p.log.Debug("Response: %s ", success)
			}
			p.done <- nil
			return
		case failure := <-p.errorCh:
			if string(failure) != "[]" {
				p.log.Debug("Could not push message to pubnub: %s", failure)
			}

			p.done <- fmt.Errorf(string(failure))
			return
		case <-time.Tick(timeoutVal):
			p.log.Debug("Handler timeout after %d secs", timeoutVal)
			p.done <- fmt.Errorf("request timeout")
			return
		}
	}
}
