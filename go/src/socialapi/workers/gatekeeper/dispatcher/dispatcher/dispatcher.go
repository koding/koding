package dispatcher

import (
	"socialapi/workers/gatekeeper/models"
	"socialapi/workers/helper"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Controller struct {
	Broker  *models.Broker
	Pubnub  *models.Pubnub
	logger  logging.Logger
	rmqConn *amqp.Connection
}

func NewController(rmqConn *rabbitmq.RabbitMQ, pubnub *models.Pubnub, broker *models.Broker) (*Controller, error) {

	rmqConn, err := rmqConn.Connect("NewGatekeeperController")
	if err != nil {
		return nil, err
	}

	handler := &Controller{
		Pubnub:  pubnub,
		Broker:  broker,
		logger:  helper.MustGetLogger(),
		rmqConn: rmqConn.Conn(),
	}

	return handler, nil
}

// DefaultErrHandler controls the errors, return false if an error occurred
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.logger.Error("an error occurred deleting gatekeeper event: %s", err)
	delivery.Ack(false)
	return false
}

// UpdateChannel sends channel update events
func (c *Controller) UpdateChannel(pm *models.PushMessage) error {
	if ok := c.isPushMessageValid(pm); !ok {
		return nil
	}

	// TODO later on Pubnub needs its own queue
	go func() {
		if err := c.Pubnub.Push(pm); err != nil {
			c.logger.Error("Could not push update channel message to pubnub: %s", err)
		}
	}()

	return c.Broker.Push(pm)
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

	// TODO later on Pubnub needs its own queue
	go func() {
		err := c.Pubnub.UpdateInstance(um)
		if err != nil {
			c.logger.Error("Could not push update instance message to pubnub: %s", err)
		}
	}()

	return c.Broker.UpdateInstance(um)
}

// NotifyUser sends user notifications to related channel
func (c *Controller) NotifyUser(nm *models.NotificationMessage) error {
	if nm.Account.Nickname == "" {
		c.logger.Error("Nickname is not set")
		return nil
	}
	nm.EventName = "message"

	// TODO later on Pubnub needs its own queue
	go func() {
		err := c.Pubnub.NotifyUser(nm)
		if err != nil {
			c.logger.Error("Could not push notification message to pubnub: %s", err)
		}
	}()

	return c.Broker.NotifyUser(nm)
}
