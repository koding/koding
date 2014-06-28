package trollmode

import (
	"errors"
	"fmt"
	"socialapi/models"
	"socialapi/workers/common/manager"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
)

const (
	MarkedAsTroll   = "api.account_marked_as_troll"
	UnMarkedAsTroll = "api.account_unmarked_as_troll"
)

func NewManager(controller worker.ErrHandler) *manager.Manager {
	m := manager.New()
	m.Controller(controller)
	m.HandleFunc(MarkedAsTroll, (*Controller).MarkedAsTroll)
	m.HandleFunc(UnMarkedAsTroll, (*Controller).UnMarkedAsTroll)
	return m
}

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

	if err := c.markChannels(account); err != nil {
		c.log.Error("Error while processing channels, err: %s ", err.Error())
		return err
	}

	if err := c.markParticipations(account); err != nil {
		c.log.Error("Error while processing participations, err: %s ", err.Error())
		return err
	}

	if err := c.markMessages(account); err != nil {
		c.log.Error("Error while processing channels messages, err: %s ", err.Error())
		return err
	}

	if err := c.markInteractions(account); err != nil {
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

func (c *Controller) markChannels(account *models.Account) error {
	var processCount = 100
	var skip = 0
	var erroredChannels []models.Channel

	ch := models.NewChannel()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"creator_id":    account.Id,
			"type_constant": models.Channel_TYPE_PRIVATE_MESSAGE,
			// 0 means safe
			"meta_bits": models.Safe,
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
			channel.MetaBits.MarkTroll()
			if err := channel.Update(); err != nil {
				c.log.Error(err.Error())
				erroredChannels = append(erroredChannels, channels[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredChannels) != 0 {
		err := errors.New(fmt.Sprintf("some errors: %v", erroredChannels))
		c.log.Error(err.Error())
		return err
	}

	return nil
}

func (c *Controller) markParticipations(account *models.Account) error {
	var processCount = 100
	var skip = 0
	var erroredChannelParticipants []models.ChannelParticipant

	cp := models.NewChannelParticipant()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id": account.Id,
			// 0 means safe
			"meta_bits": models.Safe,
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
			channelParticipant.MetaBits.MarkTroll()
			if err := channelParticipant.Update(); err != nil {
				c.log.Error(err.Error())
				erroredChannelParticipants = append(erroredChannelParticipants, channelParticipants[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredChannelParticipants) != 0 {
		err := errors.New(fmt.Sprintf("some errors: %v", erroredChannelParticipants))
		c.log.Error(err.Error())
		return err
	}

	return nil
}

func (c *Controller) markMessages(account *models.Account) error {
	var processCount = 100
	var skip = 0
	var erroredMessages []models.ChannelMessage

	cm := models.NewChannelMessage()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id": account.Id,
			// 0 means safe
			// "meta_bits": models.Safe,
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
			if err := c.markMessageLists(&message); err != nil {
				return err
			}

			// mark all message_replies items as exempt
			if err := c.markMessageReplies(&message); err != nil {
				return err
			}

			message.MetaBits.MarkTroll()
			// ChannelMessage update only updates body of the message
			if err := bongo.B.Update(message); err != nil {
				c.log.Error(err.Error())
				erroredMessages = append(erroredMessages, messages[i])
			}
		}

		// increment skip count
		skip += processCount
	}

	if len(erroredMessages) != 0 {
		err := errors.New(fmt.Sprintf("some errors: %v", erroredMessages))
		c.log.Error(err.Error())
		return err
	}

	return nil
}

func (c *Controller) markMessageLists(message *models.ChannelMessage) error {
	var processCount = 100
	var skip = 0
	var erroredMessages []models.ChannelMessageList

	cml := models.NewChannelMessageList()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"message_id": message.Id,
			"meta_bits":  models.Safe,
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
			item.MetaBits.MarkTroll()
			if err := item.Update(); err != nil {
				c.log.Error(err.Error())
				erroredMessages = append(erroredMessages, messageList[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredMessages) != 0 {
		err := errors.New(fmt.Sprintf("some errors: %v", erroredMessages))
		c.log.Error(err.Error())
		return err
	}

	return nil
}

func (c *Controller) markMessageReplies(message *models.ChannelMessage) error {
	var processCount = 100
	var skip = 0
	var erroredMessages []models.MessageReply

	mr := models.NewMessageReply()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"reply_id":  message.Id,
			"meta_bits": models.Safe,
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
			messageReply.MetaBits.MarkTroll()
			if err := messageReply.Update(); err != nil {
				c.log.Error(err.Error())
				erroredMessages = append(erroredMessages, messageList[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredMessages) != 0 {
		err := errors.New(fmt.Sprintf("some errors: %v", erroredMessages))
		c.log.Error(err.Error())
		return err
	}

	return nil
}

func (c *Controller) markInteractions(account *models.Account) error {
	var processCount = 100
	var skip = 0
	var erroredInteractions []models.Interaction

	i := models.NewInteraction()
	q := &bongo.Query{
		Selector: map[string]interface{}{
			"account_id": account.Id,
			// 0 means safe
			"meta_bits": models.Safe,
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
			interaction.MetaBits.MarkTroll()
			if err := interaction.Update(); err != nil {
				c.log.Error(err.Error())
				erroredInteractions = append(erroredInteractions, interactions[i])
			}
		}

		// increment skip count
		skip = processCount + skip
	}

	if len(erroredInteractions) != 0 {
		err := errors.New(fmt.Sprintf("some errors: %v", erroredInteractions))
		c.log.Error(err.Error())
		return err
	}

	return nil
}
func (t *Controller) UnMarkedAsTroll(account *models.Account) error {
	t.log.Critical("un marked as troll ehehe %v", account)
	return nil
}
