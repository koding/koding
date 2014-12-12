package models

import (
	"encoding/json"
	"fmt"
	"socialapi/config"
	"time"

	"github.com/koding/logging"
	"github.com/pubnub/go/messaging"
)

type Pubnub struct {
	pub *messaging.Pubnub
	log logging.Logger
}

const (
	Origin         = "pubsub.pubnub.com"
	PublishTimeout = 3 * time.Second
)

func NewPubnub(conf config.Pubnub, log logging.Logger) *Pubnub {
	messaging.SetResumeOnReconnect(false)
	messaging.SetSubscribeTimeout(3)
	messaging.LoggingEnabled(true)
	messaging.SetOrigin(Origin)
	// publishKey, subscribeKey, secretKey, cipher, ssl, uuid
	pub := messaging.NewPubnub(conf.PublishKey, conf.SubscribeKey, conf.SecretKey, "", false, "")
	pb := &Pubnub{
		pub: pub,
		log: log,
	}

	return pb
}

func (p *Pubnub) Push(pm *PushMessage) error {
	channelName := prepareChannelName(pm)

	return p.publish(channelName, pm)
}

func (p *Pubnub) Close() {
	p.pub.CloseExistingConnection()
}

func (p *Pubnub) UpdateInstance(um *UpdateInstanceMessage) error {
	channelName := prepareInstanceChannelName(um)

	return p.publish(channelName, um)
}

func (p *Pubnub) NotifyUser(nm *NotificationMessage) error {
	channelName := prepareNotificationChannelName(nm)

	return p.publish(channelName, nm)
}

func (p *Pubnub) publish(channelName string, message interface{}) error {
	pr := NewPubnubRequest()
	pr.log = p.log
	go pr.handlePublishResponse()

	go p.pub.Publish(channelName, message, pr.successCh, pr.errorCh)

	return <-pr.done
}

func prepareChannelName(pm *PushMessage) string {
	return fmt.Sprintf("channel-%s-%s-%s-%s", pm.Token, pm.Channel.Group, pm.Channel.Type, pm.Channel.Name)
}

func prepareInstanceChannelName(um *UpdateInstanceMessage) string {
	return fmt.Sprintf("instance-%s", um.Token)
}

func prepareNotificationChannelName(nm *NotificationMessage) string {
	env := config.MustGet().Environment
	return fmt.Sprintf("notification-%s-%s", env, nm.Nickname)
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
		case failure := <-pr.errorCh:
			pr.done <- fmt.Errorf("pubnub publish error")

			var arr []interface{}
			err := json.Unmarshal(failure, &arr)
			if err != nil {
				pr.log.Error("Could not unmarshal pubnub error: %s", err)
				return
			}

			if len(arr) > 0 {
				pr.log.Error("Could not push message to pubnub: %v", arr)
			}
		case <-time.After(PublishTimeout):
			pr.done <- fmt.Errorf("pubnub timeout")
		}
	}
}
