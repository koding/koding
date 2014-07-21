package pinnedpost

import (
	"socialapi/models"

	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

type Controller struct{ log logging.Logger }

func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		t.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)
		return true
	}

	t.log.Error("an error occured putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func New(log logging.Logger) *Controller {
	return &Controller{log: log}
}

// MessageCreated handles the created messages
// adds given message to the the author's pinned post channel
func (c *Controller) MessageCreated(message *models.ChannelMessage) error {
	// only posts can be marked as pinned
	if message.TypeConstant != models.ChannelMessage_TYPE_POST {
		return nil
	}

	return c.addMessage(message.AccountId, message.Id, message.InitialChannelId)
}

// MessageReplyCreated handles the created replies
func (c *Controller) MessageReplyCreated(messageReply *models.MessageReply) error {
	parent, err := messageReply.FetchParent()
	if err != nil {
		return err
	}

	// only posts can be marked as pinned
	if parent.TypeConstant != models.ChannelMessage_TYPE_POST {
		return nil
	}

	reply, err := messageReply.FetchReply()
	if err != nil {
		return err
	}

	return c.addMessage(reply.AccountId, parent.Id, parent.InitialChannelId)
}

func (c *Controller) addMessage(accountId, messageId, channelId int64) error {
	// fetch the parent channel for gorup name
	// get it from cache
	channel, err := models.ChannelById(channelId)
	if err != nil {
		return err
	}

	// get pinning channel for current user if it is created,, else create and get
	pinningChannel, err := models.EnsurePinnedActivityChannel(accountId, channel.GroupName)
	if err != nil {
		return err
	}

	// add parent message into pinning channel
	_, err = pinningChannel.AddMessage(messageId)
	// if message is already in the channel ignore the error, and mark process as successful
	if err == models.ErrAlreadyInTheChannel {
		return nil
	}

	return err
}
