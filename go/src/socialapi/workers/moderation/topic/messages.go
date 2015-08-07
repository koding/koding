package topic

import (
	"fmt"
	"socialapi/models"
	"socialapi/workers/iterator"
	"strings"
	"time"

	"github.com/koding/bongo"
)

// sleepTimeForMoveMessages holds sleeping tim per processCount, with current
// code, processMessageLists will generate at least 300 events to system
var sleepTimeForMoveMessages = time.Second * 3

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
	log := c.log.New("rootId", cl.RootId, "leafId", cl.LeafId)

	rootChannel, err := models.Cache.Channel.ById(cl.RootId)
	if err != nil {
		log.Critical("requested root channel doesnt exist.")
		return nil
	}

	leafChannel, err := models.Cache.Channel.ById(cl.LeafId)
	if err != nil {
		log.Critical("requested leaf channel doesnt exist.")
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

	f := c.processMessageLists(
		cl,
		rootChannel,
		leafChannel,
		toBeReplacedSourceString,
		toBeReplacedTargetString,
	)

	return iterator.MessageLists(log, cl.LeafId, f, sleepTimeForMoveMessages)
}

func (c *Controller) processMessageLists(
	cl *models.ChannelLink,
	rootChannel *models.Channel,
	leafChannel *models.Channel,
	toBeReplacedSourceString string,
	toBeReplacedTargetString string,
) func(messageLists []models.ChannelMessageList) error {
	return func(messageLists []models.ChannelMessageList) error {
		log := c.log.New("rootId", cl.RootId, "leafId", cl.LeafId)

		var erroredMessageLists []models.ChannelMessageList
		m := models.ChannelMessageList{}

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

			// if deletemessage option is passed delete the messages
			if cl.DeleteMessages {
				err := cm.DeleteMessageAndDependencies(true)
				if err != nil {
					log.Error("couldn't delete mesage %s", err.Error())
					erroredMessageLists = append(erroredMessageLists, messageLists[i])
				}
				continue
			}

			var channelMessageList []models.ChannelMessageList

			ml := models.ChannelMessageList{}
			// we can ignore error
			_ = bongo.B.DB.
				Model(ml).
				Table(ml.BongoName()).
				Unscoped().
				Limit(processCount).
				Where("message_id = ? AND channel_id = ?", cm.Id, rootChannel.Id).
				Find(&channelMessageList).Error

			isInRootChannel := len(channelMessageList) > 0

			if isInRootChannel {
				// we are deleting the leaf with an unscoped because we dont need the
				// data in our db anymore
				if err := bongo.B.
					Unscoped().
					Model(m).
					Table(m.TableName()).
					Delete(messageList).
					Error; err != nil {
					log.Error("Err while deleting the channel message list %s", err.Error())
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
					log.Error("couldn't update mesage %s", err.Error())
					erroredMessageLists = append(erroredMessageLists, messageLists[i])
					continue
				}

				// do not forget to send the event, other workers may need it, ps: algoliaconnecter needs it
				go bongo.B.AfterCreate(messageList)
			}

			// update message here

			cm.Body = processWithNewTag(cm.Body, toBeReplacedSourceString, toBeReplacedTargetString)

			// update the message itself
			if err := bongo.B.
				Unscoped().
				Table(cm.TableName()).
				Model(*cm). // should not be a pointer, why? dont ask me for now
				Update(cm).Error; err != nil {
				log.Error("couldn't update mesage %s", err.Error())
				erroredMessageLists = append(erroredMessageLists, messageLists[i])
				continue
			}
			cm.AfterUpdate() // do not forget to send updated event
		}

		// if error happens, return it, next time it will be re-tried
		if len(erroredMessageLists) != 0 {
			return fmt.Errorf("some errors: %v", erroredMessageLists)
		}

		return nil
	}

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
