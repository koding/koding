// Package team provides api functions for team worker
package team

import (
	"socialapi/config"
	"socialapi/models"

	"koding/db/mongodb/modelhelper"
	"strconv"

	"labix.org/v2/mgo"

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

// HandleParticipant handles participant operations, if a user joins to
func (c *Controller) HandleParticipant(cp *models.ChannelParticipant) error {
	channel := models.NewChannel()
	if err := channel.ById(cp.ChannelId); err != nil {
		return err
	}

	if channel.TypeConstant != models.Channel_TYPE_GROUP {
		return nil
	}

	group, err := modelhelper.GetGroup(channel.GroupName)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	if err == mgo.ErrNotFound {
		c.log.Error("Group: %s is not found in mongo", channel.GroupName)
		return nil
	}

	for _, channelId := range group.DefaultChannels {
		ci, err := strconv.ParseInt(channelId, 10, 64)
		if err != nil {
			return err
		}
		cp := models.NewChannelParticipant()
		cp.ChannelId = ci
		cp.AccountId = cp.AccountId

		// i wrote all of them to have a referance for future, because we
		// are gonna need this logic while implementing invitations ~ CS
		switch cp.StatusConstant {
		case models.ChannelParticipant_STATUS_ACTIVE:
			err = cp.Create()
		case models.ChannelParticipant_STATUS_BLOCKED:
			err = cp.Block()
		case models.ChannelParticipant_STATUS_LEFT:
			err = cp.Delete()
		}

		// participant can be blocked before
		if err != nil && err != models.ErrParticipantBlocked {
			return err
		}
	}

	return nil
}
