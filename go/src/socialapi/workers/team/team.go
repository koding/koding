// Package team provides api functions for team worker
package team

import (
	"socialapi/config"
	"socialapi/models"

	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

// Controller holds the required parameters for team async operations
type Controller struct {
	log    logging.Logger
	config *config.Config
}

// NewController creates a handler for consuming async operations of team
func NewController(log logging.Logger, config *config.Config) *Controller {
	return &Controller{
		log:    log,
		config: config,
	}
}

// DefaultErrHandler handles the errors, we dont need to ack a message,
// continue to the success
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

// ParticipantCreated handles participant creation operations
func (c *Controller) ParticipantCreated(cp *models.ChannelParticipant) error {
	return nil
}

// ParticipantUpdate handles participant update operations
func (c *Controller) ParticipantUpdated(cp *models.ChannelParticipant) error {
	return nil
}
