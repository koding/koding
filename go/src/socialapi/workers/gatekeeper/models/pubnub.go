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
	// TODO use logger
	timeoutVal := 3 * time.Second
	for {
		select {
		case success := <-p.successCh:
			if string(success) != "[]" {
				fmt.Println(fmt.Sprintf("Response: %s ", success))
				fmt.Println("")
			}
			p.done <- nil
			return
		case failure := <-p.errorCh:
			if string(failure) != "[]" {
				fmt.Println(fmt.Sprintf("Error Callback: %s", failure))
				fmt.Println("")
			}

			p.done <- fmt.Errorf(string(failure))
			return
		case <-time.Tick(timeoutVal):
			fmt.Println(fmt.Sprintf("Handler timeout after %d secs", timeoutVal))
			fmt.Println("")
			p.done <- fmt.Errorf("request timeout")
			return
		}
	}
}
