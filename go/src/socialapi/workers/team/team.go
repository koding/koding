// Package team provides api functions for team worker
package team

import (
	"socialapi/config"
	"socialapi/models"
	notymodels "socialapi/workers/notification/models"

	"koding/db/mongodb/modelhelper"
	"strconv"

	"gopkg.in/mgo.v2"

	"github.com/hashicorp/go-multierror"
	"github.com/koding/bongo"
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

// HandleChannel handles channel operations
func (c *Controller) HandleChannel(channel *models.Channel) error {
	if channel.TypeConstant != models.Channel_TYPE_GROUP {
		return nil
	}

	chans, err := channel.FetchAllChannelsOfGroup()
	if err != nil {
		return err
	}

	var errs *multierror.Error

	for _, ch := range chans {
		// we'r gonna innore all `not found` errors while deleting datas
		if err := ch.Delete(); err != nil && err != bongo.RecordNotFound {
			errs = multierror.Append(errs, err)
		}

		err = ch.RemoveChannelLinks()
		if err != nil && (err != models.ErrChannelNotFound || err != bongo.RecordNotFound) {
			errs = multierror.Append(errs, err)
		}

		if err := ch.DeleteChannelParticipants(); err != nil {
			return err
		}

	}

	if errs.ErrorOrNil() != nil {
		return errs
	}

	return nil
}

// HandleParticipant handles participant operations
func (c *Controller) HandleParticipant(cp *models.ChannelParticipant) error {
	channel, err := models.Cache.Channel.ById(cp.ChannelId)
	if err != nil {
		c.log.Error("Channel: %d is not found", cp.ChannelId)
		return nil
	}

	if channel.TypeConstant != models.Channel_TYPE_GROUP {
		return nil // following logic ensures that channel is a group channel
	}

	group, err := modelhelper.GetGroup(channel.GroupName)
	if err != nil && err != mgo.ErrNotFound {
		return err
	}

	if err == mgo.ErrNotFound {
		c.log.Error("Group: %s is not found in mongo", channel.GroupName)
		return nil
	}

	if err := c.handleDefaultChannels(group.DefaultChannels, cp); err != nil {
		return err
	}

	if err := c.handleParticipantRemove(cp); err != nil {
		return err
	}

	return nil
}

func (c *Controller) handleDefaultChannels(defaultChannels []string, cp *models.ChannelParticipant) error {
	for _, channelId := range defaultChannels {
		ci, err := strconv.ParseInt(channelId, 10, 64)
		if err != nil {
			c.log.Error("Couldnt parse channelId: %s, err: %s", channelId, err.Error())
			continue
		}

		if err := c.handleDefaultChannel(ci, cp); err != nil {
			return err
		}
	}

	return nil
}

func (c *Controller) handleDefaultChannel(channelId int64, cp *models.ChannelParticipant) error {
	defChan, err := models.Cache.Channel.ById(channelId)
	if err != nil && err != bongo.RecordNotFound {
		return err
	}

	if err == bongo.RecordNotFound {
		c.log.Error("Channel: %d is not found", channelId)
		return nil
	}

	// i wrote all of them to have a referance for future, because we
	// are gonna need this logic while implementing invitations ~ CS
	switch cp.StatusConstant {
	case models.ChannelParticipant_STATUS_ACTIVE:
		_, err = defChan.AddParticipant(cp.AccountId)
	case models.ChannelParticipant_STATUS_BLOCKED:
		err = defChan.RemoveParticipant(cp.AccountId)
	case models.ChannelParticipant_STATUS_LEFT:
		err = defChan.RemoveParticipant(cp.AccountId)
	}

	switch err {
	case models.ErrChannelIsLinked:
		// if channel is linked to another, add it to root channel
		root, err := defChan.FetchRoot()
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		if err == bongo.RecordNotFound {
			c.log.Error("Root Channel of %d not found", cp.ChannelId)
			return nil
		}

		// self handling with root channel
		return c.handleDefaultChannel(root.Id, cp)
	case models.ErrParticipantBlocked:
		// nothing to do here, user should be unblocked first
		return nil

	default:
		return nil
	}
}

// handleParticipantRemove removes a user from all channel participated channels
// in given group
func (c *Controller) handleParticipantRemove(cp *models.ChannelParticipant) error {
	channel, err := models.Cache.Channel.ById(cp.ChannelId)
	if err != nil {
		c.log.Error("Channel: %d is not found", cp.ChannelId)
		return nil
	}

	if channel.TypeConstant != models.Channel_TYPE_GROUP {
		return nil
	}

	if !models.IsIn(cp.StatusConstant,
		models.ChannelParticipant_STATUS_BLOCKED,
		models.ChannelParticipant_STATUS_LEFT,
	) {
		return nil
	}

	cpp := models.NewChannelParticipant()
	ids, err := cpp.FetchAllParticipatedChannelIdsInGroup(cp.AccountId, channel.GroupName)
	if err != nil && err != bongo.RecordNotFound {
		return err
	}

	if err == bongo.RecordNotFound {
		return nil
	}

	for _, id := range ids {
		ch := models.NewChannel()
		ch.Id = id
		if err := ch.RemoveParticipant(cp.AccountId); err != nil {
			return err
		}
	}
	nt := notymodels.NewNotification()
	err = nt.RemoveAllContentsRelatedWithNotification(cp.AccountId, channel.Id)
	if err != nil {
		return err
	}

	return nil
}
