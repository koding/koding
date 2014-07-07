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

func (c *Controller) ReplyCreated(messageReply *models.MessageReply) error {
	// parent message is needed for adding to pinned channel
	parentMessage := models.NewChannelMessage()
	if err := parentMessage.ById(messageReply.MessageId); err != nil {
		return err
	}

	// only posts can be marked as pinned
	if parentMessage.TypeConstant != models.ChannelMessage_TYPE_POST {
		return nil
	}

	// fetch reply itself for processsing
	reply := models.NewChannelMessage()
	if err := reply.ById(messageReply.ReplyId); err != nil {
		return err
	}

	// fetch the parent channel for gorup name
	// get it from cache
	channel, err := models.ChannelById(reply.InitialChannelId)
	if err != nil {
		return err
	}

	// get pinning channel for current user
	pinningChannel, err := models.EnsurePinnedActivityChannel(reply.AccountId, channel.GroupName)
	if err != nil {
		return err
	}

	// add parent message into pinning channel
	_, err = pinningChannel.AddMessage(parentMessage.Id)
	// if message is already in the channel ignore the error, and mark process as successful
	if err == models.AlreadyInTheChannel {
		return nil
	}

	return err
}
