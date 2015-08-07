package team

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/iterator"
	"time"

	"github.com/koding/bongo"
)

// sleepTimeForDeleteMessages holds sleeping time per processCount, with current
// code, processMessage	Lists will generate at least 300 events to system
var sleepTimeForDeleteMessages = time.Second * 3

// ChannelDeleted handles the channel delete events, for now only handles the
// channels that are group channels
func (f *Controller) ChannelDeleted(data *models.Channel) error {
	channel, err := models.Cache.Channel.ById(data.Id)
	if err != nil {
		f.log.Error("Channel: %d is not found", data.Id)
		return nil
	}

	if channel.TypeConstant != models.Channel_TYPE_GROUP {
		return nil // following logic ensures that channel is a group channel
	}

	// iterate over all channels of a group and delete their messages
	return iterator.Channels(
		f.log,
		channel.GroupName,
		f.deleteMessages,
		sleepTimeForDeleteMessages,
	)
}

func (f *Controller) deleteMessages(channels []models.Channel) error {
	for _, channel := range channels {
		if err := iterator.MessageLists(
			f.log, channel.Id, f.processMessageLists, sleepTimeForDeleteMessages,
		); err != nil {
			return err
		}
	}

	return nil
}

func (f *Controller) processMessageLists(messageLists []models.ChannelMessageList) error {
	log := f.log

	var erroredMessageLists []models.ChannelMessageList

	for i, messageList := range messageLists {
		// fetch the regarding message
		cm := models.NewChannelMessage()
		// message can be a deleted one
		err := cm.UnscopedById(messageList.MessageId)
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		if err == bongo.RecordNotFound {
			log.Critical("we do have inconsistent data in our db, message with id: %d doesnt exist in channel_message table but we have referance in our channel_message_list table id: %d", messageList.MessageId, messageList.Id)
			continue
		}

		if err := cm.DeleteMessageAndDependencies(true); err != nil {
			log.Error("couldn't delete mesage %s", err.Error())
			erroredMessageLists = append(erroredMessageLists, messageLists[i])
		}
	}

	// if error happens, return it, next time it will be re-tried
	if len(erroredMessageLists) != 0 {
		return fmt.Errorf("some errors: %v", erroredMessageLists)
	}

	return nil

}
