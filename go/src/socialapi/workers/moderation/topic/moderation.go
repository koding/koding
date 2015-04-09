// Package topic provides api functions for topic moderation worker
package topic

import (
	"errors"
	"socialapi/models"

	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const processCount = 100

// Controller holds the required parameters for moderation async operations
type Controller struct {
	log logging.Logger
}

// NewController creates a handler for consuming async operations of moderation
func NewController(log logging.Logger) *Controller {
	return &Controller{
		log: log,
	}
}

// DefaultErrHandler handles the errors, we dont need to ack a message, continue
// to the success
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

// Create moves the participants and the messages of a leaf channel to the root
// channel, it may remove the messages if the option is passed
func (c *Controller) Create(cl *models.ChannelLink) error {
	return c.process(cl)
}

// Delete just here for referance
func (c *Controller) Delete(cl *models.ChannelLink) error {
	return nil
}

// UnLink just here for referance
func (c *Controller) UnLink(cl *models.ChannelLink) error {
	return nil
}

// Blacklist moves the participants and the messages of a leaf channel to the
// root channel, it may remove the messages if the option is passed
func (c *Controller) Blacklist(cl *models.ChannelLink) error {
	return c.process(cl)
}

func (c *Controller) process(cl *models.ChannelLink) error {
	if err := c.validateRequest(cl); err != nil {
		c.log.Error("Validation failed for creating link; skipping, err: %s ", err.Error())
		return nil
	}

	if err := c.moveParticipants(cl); err != nil {
		c.log.Error("Error while processing channel participants, err: %s ", err.Error())
		return err
	}

	if err := c.moveMessages(cl); err != nil {
		c.log.Error("Error while moving messages, err: %s ", err.Error())
		return err
	}

	if err := c.updateInitialChannelIds(cl); err != nil {
		c.log.Error("Error while updating the initial channel ids, err: %s ", err.Error())
		return err
	}

	return nil
}

func (c *Controller) validateRequest(cl *models.ChannelLink) error {
	if cl == nil {
		return errors.New("channel link is not set (nil)")
	}

	if cl.Id == 0 {
		return errors.New("id is not set")
	}

	if cl.RootId == 0 {
		return errors.New("root id is not set")
	}

	if cl.LeafId == 0 {
		return errors.New("leaf id is not set")
	}

	return nil
}
