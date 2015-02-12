package collaboration

import (
	"socialapi/models"

	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

type Controller struct {
	log logging.Logger
}

func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		t.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)
		return true
	}

	t.log.Error("an error occurred putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func New(log logging.Logger) *Controller {
	return &Controller{log: log}
}

func (c *Controller) Ping(messageReply *models.MessageReply) error {
	return nil
}
