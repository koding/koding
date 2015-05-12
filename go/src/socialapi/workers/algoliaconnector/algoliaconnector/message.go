package algoliaconnector

import (
	"socialapi/models"
	"strconv"
)

func (f *Controller) MessageListSaved(listing *models.ChannelMessageList) error {
	message := models.NewChannelMessage()
	if err := message.ById(listing.MessageId); err != nil {
		return err
	}

	// no need to index join/leave messages
	if message.TypeConstant != models.ChannelMessage_TYPE_POST &&
		message.TypeConstant != models.ChannelMessage_TYPE_REPLY {
		return nil
	}

	objectId := strconv.FormatInt(message.Id, 10)
	channelId := strconv.FormatInt(listing.ChannelId, 10)

	record, err := f.get(IndexMessages, objectId)
	if err != nil &&
		!IsAlgoliaError(err, ErrAlgoliaObjectIdNotFoundMsg) &&
		!IsAlgoliaError(err, ErrAlgoliaIndexNotExistMsg) {
		return err
	}

	if record == nil {
		return f.insert(IndexMessages, map[string]interface{}{
			"objectID": objectId,
			"body":     message.Body,
			"_tags":    []string{channelId},
		})
	}

	return f.partialUpdate(IndexMessages, map[string]interface{}{
		"objectID": objectId,
		"_tags":    appendTag(record, channelId),
	})
}

func (f *Controller) MessageListDeleted(listing *models.ChannelMessageList) error {
	index, err := f.indexes.GetIndex(IndexMessages)
	if err != nil {
		return err
	}

	objectId := strconv.FormatInt(listing.MessageId, 10)

	record, err := f.get(IndexMessages, objectId)
	if err != nil &&
		!IsAlgoliaError(err, ErrAlgoliaObjectIdNotFoundMsg) &&
		!IsAlgoliaError(err, ErrAlgoliaIndexNotExistMsg) {
		return err
	}

	if tags, ok := record["_tags"]; ok {
		if t, ok := tags.([]interface{}); ok && len(t) == 1 {
			if _, err = index.DeleteObject(objectId); err != nil {
				return err
			}
			return nil
		}
	}

	return f.partialUpdate(IndexMessages, map[string]interface{}{
		"objectID": objectId,
		"_tags":    removeMessageTag(record, strconv.FormatInt(listing.ChannelId, 10)),
	})
}

func (f *Controller) MessageUpdated(message *models.ChannelMessage) error {
	return f.partialUpdate(IndexMessages, map[string]interface{}{
		"objectID": strconv.FormatInt(message.Id, 10),
		"body":     message.Body,
	})
}
