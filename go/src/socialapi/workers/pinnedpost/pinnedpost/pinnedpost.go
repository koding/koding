package pinnedpost

import (
	"socialapi/models"
	"time"

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

	// update all the channels that contain this message
	// this is done for changing the order of the pinned messages
	defer c.updateAllContainingChannels(parent, reply)

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
	if err == models.AlreadyInTheChannel {
		return nil
	}

	return err
}

// updateAllContainingChannels fetch all channels that parent is in and
// updates those channels except the user who did the action.
func (c *Controller) updateAllContainingChannels(parent, reply *models.ChannelMessage) error {
	cml := models.NewChannelMessageList()
	channels, err := cml.FetchMessageChannels(parent.Id)
	if err != nil {
		return err
	}

	if len(channels) == 0 {
		return nil
	}

	for _, channel := range channels {
		// if channel type is group, we dont need to update group's updatedAt
		if channel.TypeConstant == models.Channel_TYPE_GROUP {
			continue
		}

		// initiatorAccontId refers to users who did the action
		if channel.CreatorId == reply.AccountId {
			cml, err := channel.FetchMessageList(parent.Id)
			if err != nil {
				c.log.Error("error fetching message list for", parent.Id, err)
				continue
			}

			// `Glance` for author, so on next new message, unread count is right
			err = cml.Glance()
			if err != nil {
				c.log.Error("error glancing for messagelist", parent.Id, err)
				continue
			}

			// no need to tell user they did an action
			continue
		}

		// pinned activity channel holds messages one by one
		//
		// this should be removed after private message refactoring
		if channel.TypeConstant != models.Channel_TYPE_PINNED_ACTIVITY {
			channel.UpdatedAt = time.Now().UTC()
			if err := channel.Update(); err != nil {
				c.log.Error("channel update failed", err)
			}
			continue
		}

		cml := models.NewChannelMessageList()
		err := cml.UpdateAddedAt(channel.Id, parent.Id)
		if err != nil {
			c.log.Error("message list update failed", err)
		}

		pclu := models.PinnedChannelListUpdatedEvent{
			Channel: channel,
			Message: *parent,
			Reply:   *reply,
		}

		if err := cml.Emit("pinned_channel_list_updated", pclu); err != nil {
			c.log.Error("err %s", err.Error())
		}
	}

	return nil
}
