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

	// add parent message to the author's pinned message list
	err = c.addMessage(parent.AccountId, parent.Id, parent.InitialChannelId)
	if err != nil && err != models.AlreadyInTheChannel {
		return err
	}

	// no need to try to add the same message again to the author's pinned
	// message list
	if parent.AccountId == reply.AccountId {
		return nil
	}

	// add parent message to the replier's pinned message list
	err = c.addMessage(reply.AccountId, parent.Id, parent.InitialChannelId)
	if err != nil && err != models.AlreadyInTheChannel {
		return err
	}

	return nil
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
