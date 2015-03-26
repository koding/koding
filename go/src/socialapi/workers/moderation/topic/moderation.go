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

// Unlink is not implemented yet
func (c *Controller) UnLink(cl *models.ChannelLink) error {
	if err := c.validateRequest(cl); err != nil {
		c.log.Error("Validation failed for creating link; skipping, err: %s ", err.Error())
		return nil
	}

	c.log.Info("nothing to do for unlink for now")

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
// participation with the new root node's channel id, it is always safe to
// return error whever we encounter one
func (c *Controller) moveParticipants(cl *models.ChannelLink) error {
	var processCount = 100
	var erroredChannelParticipants []models.ChannelParticipant

	for {

		var channelParticipants []models.ChannelParticipant

		m := models.ChannelParticipant{}
		// fetch all records, even deleted ones, because we are not gonna need
		// them anymore
		err := bongo.B.DB.
			Model(m).
			Table(m.BongoName()).
			Unscoped().
			Limit(processCount).
			Where("channel_id = ?", cl.LeafId).
			Find(&channelParticipants).Error

		// if we encounter an error do not continue, if we cant find any
		// result, it can be excluded from the error case, because since we
		// will not be able to process any message system will return
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		// we processed all channel participants, no need to continue anymore
		if len(channelParticipants) == 0 {
			c.log.Info("doesnt have any participants to process")
			break
		}

		for i, channelParticipant := range channelParticipants {
			// fetch the root channel's participant, if exists
			rootParticipation := models.NewChannelParticipant()
			rootParticipation.ChannelId = cl.RootId
			rootParticipation.AccountId = channelParticipant.AccountId
			err := rootParticipation.FetchParticipant()
			if err != nil && err != bongo.RecordNotFound {
				// dont append to erroredChannelParticipants because we need the
				// data here
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

			} else {
				// if we get here it means the user is a member of the new root node
				// if the user is already participant of root channel, delete the
				// leaf node participation

				if err := bongo.B.
					Unscoped().
					Table(m.BongoName()).
					Delete(channelParticipant).
					Error; err != nil {
					c.log.Error("Err while deleting the channel participation %s", err.Error())
					erroredChannelParticipants = append(erroredChannelParticipants, channelParticipants[i])
					continue
				}
			}

			// send deleted event
			bongo.B.AfterDelete(channelParticipants[i])
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
		return nil
	}

	leafChannel, err := models.ChannelById(cl.LeafId)
	if err != nil {
		c.log.Critical("requested leaf channel doesnt exist. ChannelId: %d", cl.LeafId)
		return nil
	}

	// change what
	toBeReplacedSourceString := "#" + leafChannel.Name
	// with what
	toBeReplacedTargetString := "#" + rootChannel.Name

	// if the new root channel is our group channel, than do not replace the topics with group name :)
	if cl.DeleteMessages || rootChannel.TypeConstant == models.Channel_TYPE_GROUP {
		toBeReplacedTargetString = leafChannel.Name
	}

	m := models.ChannelMessageList{}
	for {
		var messageLists []models.ChannelMessageList

		// fetch all records, even deleted ones, because we are not gonna need
		// them anymore
		err := bongo.B.DB.
			Unscoped().
			Model(m).
			Table(m.TableName()).
			Limit(processCount).
			Where("channel_id = ?", cl.LeafId).
			Find(&messageLists).Error

		// if we encounter an error do not continue, if we cant find any
		// result, it can be excluded from the error case, because since we
		// will not be able to process any message system will return
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		// we processed all channel messages. or no message exits
		if len(messageLists) == 0 {
			break
		}

		for i, messageList := range messageLists {
			// fetch the regarding message
			cm := models.NewChannelMessage()
			// message can be a deleted one
			err := cm.UnscopedById(messageList.MessageId)
			if err != nil && err != bongo.RecordNotFound {
				return err
			}

			if err == bongo.RecordNotFound {
				c.log.Critical("we do have inconsistent data in our db, message with id: %d doesnt exist in channel_message table but we have referance in our channel_message_list table id: %d", messageList.MessageId, messageList.Id)
				continue
			}

			// if deletemessage option is passed delete the messages
			if cl.DeleteMessages {
				err := cm.DeleteMessageAndDependencies(true)
				if err != nil {
					c.log.Error("Err while deleting the mesage %s", err.Error())
					erroredMessageLists = append(erroredMessageLists, messageLists[i])
				}
				continue
			}

			isInRootChannel, _ := models.NewChannelMessageList().IsInChannel(cm.Id, rootChannel.Id)
			if isInRootChannel {

				// we are deleting the leaf with an unscoped because we dont need the
				// data in our db anymore
				if err := bongo.B.
					Unscoped().
					Model(m).
					Table(m.TableName()).
					Delete(messageList).
					Error; err != nil {
					c.log.Error("Err while deleting the channel message list %s", err.Error())
					erroredMessageLists = append(erroredMessageLists, messageLists[i])
				}

				// do not forget to send the event, other workers may need it, ps: algoliaconnecter needs it
				go bongo.B.AfterDelete(messageList)

			} else {
				// update the message itself, without callbacks
				if err := bongo.B.
					Unscoped().
					Table(m.TableName()).
					Model(&messageList).
					UpdateColumn("channel_id", cl.RootId).
					Error; err != nil && !models.IsUniqueConstraintError(err) {
					c.log.Error("Err while updating the mesage %s", err.Error())
					erroredMessageLists = append(erroredMessageLists, messageLists[i])
					continue
				}

				// do not forget to send the event, other workers may need it, ps: algoliaconnecter needs it
				go bongo.B.AfterCreate(messageList)
			}

			// update message here

			// just a little shortcut here, update the initial channel id
			if cm.InitialChannelId == leafChannel.Id {
				cm.InitialChannelId = rootChannel.Id
			}

			// replace all occurences of the leaf node hashbangs with the root
			// nodes. We _can't_ determine if the multiple occurences of the
			// same `Name` constitues a meaningful sentence - yes we can, but it
			// is not feasible for now...
			cm.Body = processWithNewTag(cm.Body, toBeReplacedSourceString, toBeReplacedTargetString)

			// update the message itself
			if err := bongo.B.
				Unscoped().
				Table(cm.TableName()).
				Model(*cm). // should not be a pointer, why? dont ask me for now
				Update(cm).Error; err != nil {
				c.log.Error("Err while updating the mesage %s", err.Error())
				erroredMessageLists = append(erroredMessageLists, messageLists[i])
				continue
			}
			cm.AfterUpdate() // do not forget to send updated event
		}
	}

	if len(erroredMessageLists) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredMessageLists))
	}

	return nil
}

// updateInitialChannelIds updates the message's initial channel id properties,
// we are already updating the channel_message's initial channel id while
// iterating over the messages but there can be some messages that are created
// in that channel initially, but then can be moved to other channels
func (c *Controller) updateInitialChannelIds(cl *models.ChannelLink) error {
	var processCount = 100

	var erroredMessages []models.ChannelMessage

	for {
		var messages []models.ChannelMessage

		// fetch all records, even deleted ones, because we are not gonna need
		// them anymore
		err := bongo.B.DB.
			Model(models.ChannelMessage{}).
			Unscoped().
			Limit(processCount).
			Where("initial_channel_id = ?", cl.LeafId).
			Find(&messages).Error

		// if we encounter an error do not continue, if we cant find any
		// result, it can be excluded from the error case, because since we
		// will not be able to process any message system will return
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		// we processed all channel messages. or no message exits
		if len(messages) == 0 {
			break
		}

		for i, message := range messages {
			// fetch the regarding message
			cm := models.NewChannelMessage()
			err := cm.UnscopedById(message.Id)
			if err != nil && err != bongo.RecordNotFound {
				return err
			}

			if err == bongo.RecordNotFound {
				// message can be deleted in the mean time
				continue
			}

			cm.InitialChannelId = cl.RootId

			// update the message itself. Used bongo.Update because
			// ChannelMessage's Update method is overwritten
			if err := bongo.B.
				Unscoped().
				Table(cm.TableName()).
				Model(*cm). // should not be a pointer, why? dont ask me for now
				Update(cm).Error; err != nil {
				c.log.Error("Err while updating the mesage %s", err.Error())
				erroredMessages = append(erroredMessages, messages[i])
				continue
			}
			cm.AfterUpdate() // do not forget to send updated event

		}
	}

	if len(erroredMessages) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredMessages))
	}

	return nil
}

func processWithNewTag(body, leaf, root string) string {
	// replace all occurences of the leaf node hashbangs with the root
	// nodes. We _can't_ determine if the multiple occurences of the
	// same `Name` constitues a meaningful sentence - yes we can, but it
	// is not feasible for now...
	body = strings.Replace(body, leaf, root, -1)

	// remove multiple consecutive occurrences of the same tag, if exists
	splittedBody := strings.Split(body, root)
	modifiedBody := make([]string, 0)

	for i := 0; i < len(splittedBody); i++ {
		r := splittedBody[i]
		if r == "" || r == " " {
			if i == 0 || i == len(splittedBody)-1 {
				// if we dont have  any previous or next, add it
				modifiedBody = append(modifiedBody, r)
			}
		} else {
			modifiedBody = append(modifiedBody, r)
		}
	}

	return strings.Join(modifiedBody, root)
}
