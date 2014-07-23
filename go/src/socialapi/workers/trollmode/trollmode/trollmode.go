package trollmode

import (
	"errors"
	"fmt"
	"socialapi/models"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const (
	MarkedAsTrollEvent   = "marked_as_troll"
	UnMarkedAsTrollEvent = "unmarked_as_troll"
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
	c.log.Error("an error occured putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func (c *Controller) MarkedAsTroll(account *models.Account) error {
	if err := c.validateRequest(account); err != nil {
		c.log.Error("Validation failed for marking troll; skipping, err: %s ", err.Error())
		return nil
	}

	if err := c.markChannels(account, models.Safe); err != nil {
		c.log.Error("Error while processing channels, err: %s ", err.Error())
		return err
	}

	if err := c.markParticipations(account, models.Safe); err != nil {
		c.log.Error("Error while processing participations, err: %s ", err.Error())
		return err
	}

	if err := c.markMessages(account, models.Safe); err != nil {
		c.log.Error("Error while processing channels messages, err: %s ", err.Error())
		return err
	}

	if err := c.markInteractions(account, models.Safe); err != nil {
		c.log.Error("Error while processing interactions, err: %s ", err.Error())
		return err
	}

	return nil
}

func (c *Controller) UnMarkedAsTroll(account *models.Account) error {
	if err := c.validateRequest(account); err != nil {
		c.log.Error("Validation failed for un-marking troll; skipping, err: %s ", err.Error())
		return nil
	}

	if err := c.markChannels(account, models.Troll); err != nil {
		c.log.Error("Error while processing channels, err: %s ", err.Error())
		return err
	}

	if err := c.markParticipations(account, models.Troll); err != nil {
		c.log.Error("Error while processing participations, err: %s ", err.Error())
		return err
	}

	if err := c.markMessages(account, models.Troll); err != nil {
		c.log.Error("Error while processing channels messages, err: %s ", err.Error())
		return err
	}

	if err := c.markInteractions(account, models.Troll); err != nil {
		c.log.Error("Error while processing interactions, err: %s ", err.Error())
		return err
	}

	return nil
}

func (c *Controller) validateRequest(account *models.Account) error {
	if account == nil {
		return errors.New("account is not set (nil)")
	}

	if account.Id == 0 {
		return errors.New("account id is not set")
	}

	return nil
}

func (c *Controller) markChannels(account *models.Account, currentStatus models.MetaBits) error {
	var processCount = 100
	var skip = 0
	var erroredChannels []models.Channel

	ch := models.NewChannel()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"creator_id":    account.Id,
			"type_constant": models.Channel_TYPE_PRIVATE_MESSAGE,
			"meta_bits":     currentStatus,
		},
		Pagination: *bongo.NewPagination(processCount, 0),
	}

	for {
		// set skip everytime here
		q.Pagination.Skip = skip
		var channels []models.Channel
		if err := ch.Some(&channels, q); err != nil {
			return err
		}

		// we processed all messages
		if len(channels) <= 0 {
			break
		}

		for i, channel := range channels {

			if currentStatus == models.Safe {
				channel.MetaBits.Mark(models.Troll)
			} else {
				channel.MetaBits.UnMark(models.Troll)
			}

			if err := channel.Update(); err != nil {
				erroredChannels = append(erroredChannels, channels[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredChannels) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredChannels))
	}

	return nil
}

func (c *Controller) markParticipations(account *models.Account, currentStatus models.MetaBits) error {
	var processCount = 100
	var skip = 0
	var erroredChannelParticipants []models.ChannelParticipant

	cp := models.NewChannelParticipant()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id": account.Id,
			"meta_bits":  currentStatus,
		},
		Pagination: *bongo.NewPagination(processCount, 0),
	}

	for {

		// set skip everytime here
		q.Pagination.Skip = skip
		var channelParticipants []models.ChannelParticipant
		if err := cp.Some(&channelParticipants, q); err != nil {
			return err
		}

		// we processed all channel participants
		if len(channelParticipants) <= 0 {
			break
		}

		for i, channelParticipant := range channelParticipants {

			if currentStatus == models.Safe {
				channelParticipant.MetaBits.Mark(models.Troll)
			} else {
				channelParticipant.MetaBits.UnMark(models.Troll)
			}

			if err := channelParticipant.Update(); err != nil {
				erroredChannelParticipants = append(erroredChannelParticipants, channelParticipants[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredChannelParticipants) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredChannelParticipants))
	}

	return nil
}

func (c *Controller) markMessages(account *models.Account, currentStatus models.MetaBits) error {
	var processCount = 100
	var skip = 0
	var erroredMessages []models.ChannelMessage

	cm := models.NewChannelMessage()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id": account.Id,
			// 0 means safe
			"meta_bits": currentStatus,
		},
		Pagination: *bongo.NewPagination(processCount, 0),
	}

	for {

		// set skip everytime here
		q.Pagination.Skip = skip
		var messages []models.ChannelMessage
		if err := cm.Some(&messages, q); err != nil {
			return err
		}

		// we processed all channel participants
		if len(messages) <= 0 {
			break
		}

		for i, message := range messages {
			// mark all message_list items as exempt
			if err := c.markMessageLists(&message, currentStatus); err != nil {
				return err
			}

			// mark all message_replies items as exempt
			if err := c.markMessageReplies(&message, currentStatus); err != nil {
				return err
			}

			if currentStatus == models.Safe {
				message.MetaBits.Mark(models.Troll)
			} else {
				message.MetaBits.UnMark(models.Troll)
			}

			// ChannelMessage update only updates body of the message
			if err := bongo.B.Update(message); err != nil {
				erroredMessages = append(erroredMessages, messages[i])
			}
		}

		// increment skip count
		skip += processCount
	}

	if len(erroredMessages) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredMessages))
	}

	return nil
}

func (c *Controller) markMessageLists(message *models.ChannelMessage, currentStatus models.MetaBits) error {
	var processCount = 100
	var skip = 0
	var erroredMessages []models.ChannelMessageList

	cml := models.NewChannelMessageList()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id": message.Id,
			"meta_bits":  currentStatus,
		},
		Pagination: *bongo.NewPagination(processCount, 0),
	}

	for {

		// set skip everytime here
		q.Pagination.Skip = skip
		var messageList []models.ChannelMessageList
		if err := cml.Some(&messageList, q); err != nil {
			return err
		}

		// we processed all channel participants
		if len(messageList) <= 0 {
			break
		}

		for i, item := range messageList {

			if currentStatus == models.Safe {
				item.MetaBits.Mark(models.Troll)
			} else {
				item.MetaBits.UnMark(models.Troll)
			}

			if err := item.Update(); err != nil {
				erroredMessages = append(erroredMessages, messageList[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredMessages) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredMessages))
	}

	return nil
}

func (c *Controller) markMessageReplies(message *models.ChannelMessage, currentStatus models.MetaBits) error {
	var processCount = 100
	var skip = 0
	var erroredMessages []models.MessageReply

	mr := models.NewMessageReply()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"reply_id":  message.Id,
			"meta_bits": currentStatus,
		},
		Pagination: *bongo.NewPagination(processCount, 0),
	}

	for {

		// set skip everytime here
		q.Pagination.Skip = skip
		var messageList []models.MessageReply
		if err := mr.Some(&messageList, q); err != nil {
			return err
		}

		// we processed all channel participants
		if len(messageList) <= 0 {
			break
		}

		for i, messageReply := range messageList {
			if currentStatus == models.Safe {
				messageReply.MetaBits.Mark(models.Troll)
			} else {
				messageReply.MetaBits.UnMark(models.Troll)
			}

			if err := messageReply.Update(); err != nil {
				erroredMessages = append(erroredMessages, messageList[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredMessages) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredMessages))
	}

	return nil
}

func (c *Controller) markInteractions(account *models.Account, currentStatus models.MetaBits) error {
	var processCount = 100
	var skip = 0
	var erroredInteractions []models.Interaction

	i := models.NewInteraction()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id": account.Id,
			// 0 means safe
			"meta_bits": currentStatus,
		},
		Pagination: *bongo.NewPagination(processCount, 0),
	}

	for {
		// set skip everytime here
		q.Pagination.Skip = skip
		var interactions []models.Interaction
		if err := i.Some(&interactions, q); err != nil {
			return err
		}

		// we processed all channel participants
		if len(interactions) <= 0 {
			break
		}

		for i, interaction := range interactions {
			if currentStatus == models.Safe {
				interaction.MetaBits.Mark(models.Troll)
			} else {
				interaction.MetaBits.UnMark(models.Troll)
			}

			if err := interaction.Update(); err != nil {
				erroredInteractions = append(erroredInteractions, interactions[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredInteractions) != 0 {
		return errors.New(fmt.Sprintf("some errors: %v", erroredInteractions))
	}

	return nil
}
