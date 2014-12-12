package dispatcher

import (
	"socialapi/workers/gatekeeper/models"
	"socialapi/workers/helper"
	"sync"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
	"github.com/streadway/amqp"
)

type Controller struct {
	Realtime []models.Realtime
	logger   logging.Logger
	rmqConn  *amqp.Connection
}

func NewController(rmqConn *rabbitmq.RabbitMQ, adapters ...models.Realtime) (*Controller, error) {

	rmqConn, err := rmqConn.Connect("NewGatekeeperController")
	if err != nil {
		return nil, err
	}

	handler := &Controller{
		Realtime: make([]models.Realtime, 0),
		logger:   helper.MustGetLogger(),
		rmqConn:  rmqConn.Conn(),
	}

	handler.Realtime = append(handler.Realtime, adapters...)

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
	// TODO add timeout

	var wg sync.WaitGroup
	for _, adapter := range c.Realtime {
		wg.Add(1)
		go func(r models.Realtime) {
			r.Push(pm)
			wg.Done()
		}(adapter)
	}

	wg.Wait()

	return nil
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

	if pm.Token == "" {
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

	// TODO add timeout

	var wg sync.WaitGroup
	for _, adapter := range c.Realtime {
		wg.Add(1)
		go func(r models.Realtime) {
			r.UpdateInstance(um)
			wg.Done()
		}(adapter)
	}

	wg.Wait()

	return nil
}

// NotifyUser sends user notifications to related channel
func (c *Controller) NotifyUser(nm *models.NotificationMessage) error {
	if nm.Nickname == "" {
		c.logger.Error("Nickname is not set")
		return nil
	}
	nm.EventName = "message"

	// TODO add timeout

	var wg sync.WaitGroup
	for _, adapter := range c.Realtime {
		wg.Add(1)
		go func(r models.Realtime) {
			r.NotifyUser(nm)
			wg.Done()
		}(adapter)
	}

	wg.Wait()

	return nil
}
