package topic

import (
	"errors"
	"fmt"
	"socialapi/models"
	"strings"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

type Controller struct {
	log logging.Logger
}

func NewController(log logging.Logger) *Controller {
	return &Controller{
		log: log,
	}
}

// this worker is completely idempotent, so no need to cut the circuit
func (c *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	c.log.Error("an error occurred putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func (c *Controller) CreateLink(cl *models.ChannelLink) error {
	if err := c.validateRequest(cl); err != nil {
		c.log.Error("Validation failed for creating link; skipping, err: %s ", err.Error())
		return nil
	}

	if err := c.moveParticipants(cl); err != nil {
		c.log.Error("Error while processing channel participants, err: %s ", err.Error())
		return err
	}

	if err := c.moveMessages(cl); err != nil {
		c.log.Error("Error while processing messages, err: %s ", err.Error())
		return err
	}

	return nil
}

func (c *Controller) UnLink(cl *models.ChannelLink) error {
	if err := c.validateRequest(cl); err != nil {
		c.log.Error("Validation failed for creating link; skipping, err: %s ", err.Error())
		return nil
	}

	if err := c.moveParticipants(cl); err != nil {
		c.log.Error("Error while processing channel participants, err: %s ", err.Error())
		return err
	}

	if err := c.moveMessages(cl); err != nil {
		c.log.Error("Error while processing messages, err: %s ", err.Error())
		return err
	}

	return nil
}

func (c *Controller) Blacklist(cl *models.ChannelLink) error {
	if err := c.validateRequest(cl); err != nil {
		c.log.Error("Validation failed for creating link; skipping, err: %s ", err.Error())
		return nil
	}

	if err := c.moveParticipants(cl); err != nil {
		c.log.Error("Error while processing channel participants, err: %s ", err.Error())
		return err
	}

	if err := c.moveMessages(cl); err != nil {
		c.log.Error("Error while processing messages, err: %s ", err.Error())
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

// moveParticipants moves the participants of the leaf node to the root node it
// doesnt update the lastSeenAt time of the participants on channels if the user
// already a participant of the root node, just removes the participation from
// leaf node, if user only participant of the leaf node updates the current
// participation with the new root node's channel id
func (c *Controller) moveParticipants(cl *models.ChannelLink) error {
	var processCount = 100
	var erroredChannelParticipants []models.ChannelParticipant

	for {

		var channelParticipants []models.ChannelParticipant

		// fetch all records, even deleted ones, because we are not gonna need
		// them anymore
		err := bongo.B.DB.
			Model(models.ChannelParticipant{}).
			Unscoped().
			Limit(processCount).
			Where("channel_id = ?", cl.LeafId).
			Find(&channelParticipants).Error

		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		// we processed all channel participants
		if len(channelParticipants) <= 0 {
			c.log.Info("doesnt have any participants to process")
			break
		}

		for i, channelParticipant := range channelParticipants {
			// fetch the root channel's participation, if exists
			rootParticipation := models.NewChannelParticipant()
			rootParticipation.ChannelId = cl.RootId
			rootParticipation.AccountId = channelParticipant.AccountId
			err := rootParticipation.FetchParticipant()
			if err != nil && err != bongo.RecordNotFound {
				return err
			}

			// if the user is not the participant of root node, update the
			// current ChannelParticipant record with the root node's channel id
			if err == bongo.RecordNotFound {
				channelParticipant.ChannelId = cl.RootId
				if err := channelParticipant.Update(); err != nil {
					c.log.Error("Err while swapping channel ids %s", err.Error())
					erroredChannelParticipants = append(erroredChannelParticipants, channelParticipants[i])
				}

				// do not go further, we are done for this iteration
				continue
			}

			// if we get here it means the user is a member of the new root node
			// if the user is already participant of root channel, delete the
			// leaf node participation
			if err := bongo.B.Unscoped().Delete(channelParticipant).Error; err != nil {
				//
				// TODO do we need to send an event here?
				//
				c.log.Error("Err while deleting the channel participation %s", err.Error())
				erroredChannelParticipants = append(erroredChannelParticipants, channelParticipants[i])
			}
		}
	}

	// if error happens, return it, next time it will be re-tried
	if len(erroredChannelParticipants) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredChannelParticipants))
	}

	return nil
}

// moveMessages moves the leaf channel's messages to the root node, while moving
// them first iterates over the chanel_message_list and process them one by one,
// if the message already member of the root channel, it doesnt add again, and
// removes it from leaf node immediately. Secondly updates the message's body,
// if the channel is blacklisted removes the hashbang(#) eg: #js -> js, if the
// channel is just linked replaces only the occurences with a hashbang eg: #js
// -> #javascript. At the end, if the message is directly posted to the linked
// channel, it has InitialChannelId, we should replace it with the parent's
// channel id
func (c *Controller) moveMessages(cl *models.ChannelLink) error {
	var processCount = 100

	var erroredMessageLists []models.ChannelMessageList

	rootChannel, err := models.ChannelById(cl.RootId)
	if err != nil {
		c.log.Critical("requested root channel doesnt exist. ChannelId: %d", cl.RootId)
		c.log.Critical("closing the circuit")
		return nil
	}

	leafChannel, err := models.ChannelById(cl.LeafId)
	if err != nil {
		c.log.Critical("requested leaf channel doesnt exist. ChannelId: %d", cl.LeafId)
		c.log.Critical("closing the circuit")
		return nil
	}

	for {
		var messageLists []models.ChannelMessageList

		// fetch all records, even deleted ones, because we are not gonna need
		// them anymore
		err := bongo.B.DB.
			Model(models.ChannelMessageList{}).
			Unscoped().
			Limit(processCount).
			Where("channel_id = ?", cl.LeafId).
			Find(&messageLists).Error

		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		// we processed all channel messages. or no message exits
		if len(messageLists) <= 0 {
			break
		}

		for i, messageList := range messageLists {
			// fetch the regarding message
			cm := models.NewChannelMessage()
			err := cm.UnscopedById(messageList.MessageId)
			if err != nil && err != bongo.RecordNotFound {
				return err
			}

			if err == bongo.RecordNotFound {
				c.log.Critical("we do have inconsistent data in our db, message with id: %d doesnt exist in channel_message table but we have referance in our channel_message_list table id: %d", messageList.MessageId, messageList.Id)
				c.log.Critical("skipping this iteration")
				continue
			}

			// update message here

			// just a little shortcut here, update the initial channel id
			if cm.InitialChannelId == leafChannel.Id {
				cm.InitialChannelId = rootChannel.Id
			}

			// replace all occurences of the leaf node hashbangs with the root
			// nodes. We can't determine if the multiple occurences of the same
			// `Name` constitues a meaningful sentence - yes we can but it is
			// not feasible for now...
			cm.Body = strings.Replace(cm.Body, "#"+leafChannel.Name, "#"+rootChannel.Name, -1)

			// update the message itself
			if err := cm.Update(); err != nil {
				c.log.Error("Err while updating the mesage %s", err.Error())
				erroredMessageLists = append(erroredMessageLists, messageLists[i])
				continue
			}

			// update message ends

			// make sure message is in rootChannel
			if _, err := rootChannel.EnsureMessage(cm.Id, true); err != nil {
				c.log.Error("Err while ensuring message in the channel %s", err.Error())
				erroredMessageLists = append(erroredMessageLists, messageLists[i])
			}

			if err := bongo.B.Unscoped().Delete(messageList).Error; err != nil {
				//
				// TODO do we need to send an event here?
				//
				c.log.Error("Err while deleting the channel message list %s", err.Error())
				erroredMessageLists = append(erroredMessageLists, messageLists[i])
			}
		}
	}

	if len(erroredMessageLists) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredMessageLists))
	}

	return nil
}
