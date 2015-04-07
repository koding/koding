package topic

import (
	"fmt"
	"socialapi/models"

	"github.com/koding/bongo"
)

// updateInitialChannelIds updates the message's initial channel id properties,
// we are already updating the channel_message's initial channel id while
// iterating over the messages but there can be some messages that are created
// in that channel initially, but then can be moved to other channels
//
// Under normal circumstances this code should not do anything, because all of
// the messages has group's channel id as initial_channel_id but this code is a
// guardian for any kind of posiible leak and future channel based requirements
func (c *Controller) updateInitialChannelIds(cl *models.ChannelLink) error {

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
		return fmt.Errorf("some errors: %v", erroredMessages)
	}

	return nil
}
