package dispatcher

import (
	"fmt"
	"socialapi/workers/helper"
	"socialapi/workers/realtime/models"
	"time"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Controller struct {
	Broker  *models.Broker
	Pubnub  *models.PubNub
	logger  logging.Logger
	rmqConn *amqp.Connection
}

func NewController(rmqConn *rabbitmq.RabbitMQ, pubnub *models.PubNub, broker *models.Broker) *Controller {

	return &Controller{
		Pubnub:  pubnub,
		Broker:  broker,
		logger:  helper.MustGetLogger(),
		rmqConn: rmqConn.Conn(),
	}
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.logger.Error("an error occurred deleting dispatcher event: %s", err)
	delivery.Ack(false)
	return false
}

// UpdateChannel sends channel update events
func (c *Controller) UpdateChannel(pm *models.PushMessage) error {
	if ok := c.isPushMessageValid(pm); !ok {
		return nil
	}

	pm.EventId = createEventId()

	go func() {
		if err := c.Broker.UpdateChannel(pm); err != nil {
			c.logger.Error("Could not push update channel message with body %s to broker: %s", pm.Message.Body, err)
		}
	}()

	return c.Pubnub.UpdateChannel(pm)
}

func (c *Controller) isPushMessageValid(pm *models.PushMessage) bool {
	if pm.Channel.Id == 0 {
		c.logger.Error("Invalid request: channel id is not set")
		return false
	}

	if pm.EventName == "" {
		c.logger.Error("Invalid request: event name is not set")
		return false
	}

	if pm.Channel.Token == "" {
		c.logger.Error("Invalid request: token is not set")
		return false
	}

	return true
}

// UpdateMessage sends message update events
func (c *Controller) UpdateMessage(um *models.UpdateInstanceMessage) error {
	if um.Token == "" {
		c.logger.Error("Token is not set")
		return nil
	}

	um.EventId = createEventId()

	go func() {
		err := c.Broker.UpdateInstance(um)
		if err != nil {
			c.logger.Error("Could not push update instance message with id %d to broker: %s", um.Message.Id, err)
		}
	}()

	return c.Pubnub.UpdateInstance(um)
}

// NotifyUser sends user notifications to related channel
func (c *Controller) NotifyUser(nm *models.NotificationMessage) error {
	if nm.Account.Nickname == "" {
		c.logger.Error("Nickname is not set")
		return nil
	}

	nm.EventName = "message"
	nm.EventId = createEventId()

	go func() {
		err := c.Broker.NotifyUser(nm)
		if err != nil {
			c.logger.Error("Could not send push notification message '%s' to user %s broker: %s", nm.EventName, nm.Account.Nickname, err)
		}
	}()

	return c.Pubnub.NotifyUser(nm)
}

func (c *Controller) GrantMessagePublicAccess(um *models.UpdateInstanceMessage) error {
	muc := models.NewMessageUpdateChannel(*um)

	return c.Pubnub.GrantPublicAccess(muc)
}

func (c *Controller) RevokeChannelAccess(rca *models.RevokeChannelAccess) error {
	channel := models.Channel{
		Token: rca.ChannelToken,
	}
	pmc := models.NewPrivateMessageChannel(channel)

	for _, token := range rca.Tokens {
		a := &models.Authenticate{
			Account: &models.Account{Token: token},
		}
		if err := c.Pubnub.RevokeAccess(a, pmc); err != nil {
			return err
		}
	}

	return nil
}

func createEventId() string {
	return fmt.Sprintf("server-%d", time.Now().UnixNano())
}
