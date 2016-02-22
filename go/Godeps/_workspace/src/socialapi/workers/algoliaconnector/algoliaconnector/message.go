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

	if !message.SearchIndexable() {
		return nil
	}

	objectID := strconv.FormatInt(message.Id, 10)
	channelId := strconv.FormatInt(listing.ChannelId, 10)

	// if message is doesnt exist on algolia it will be created and tag will be
	// added, if it is already created before tag will be added
	return f.partialUpdate(IndexMessages, map[string]interface{}{
		"objectID": objectID,
		"body":     message.Body,
		"_tags": map[string]interface{}{
			"_operation": "AddUnique",
			"value":      channelId,
		},
	})
}

func (f *Controller) MessageListDeleted(listing *models.ChannelMessageList) error {
	index, err := f.indexes.GetIndex(IndexMessages)
	if err != nil {
		return err
	}

	objectID := strconv.FormatInt(listing.MessageId, 10)

	record, err := f.get(IndexMessages, objectID)
	if err != nil &&
		!IsAlgoliaError(err, ErrAlgoliaObjectIDNotFoundMsg) &&
		!IsAlgoliaError(err, ErrAlgoliaIndexNotExistMsg) {
		return err
	}

	// if record is not there, just ignore
	if record == nil {
		return nil
	}

	if tags, ok := record["_tags"]; ok {
		if t, ok := tags.([]interface{}); ok && len(t) == 1 {
			if _, err = index.DeleteObject(objectID); err != nil {
				return err
			}
			return nil
		}
	}

	return f.RemoveTag(
		IndexMessages,
		objectID,
		strconv.FormatInt(listing.ChannelId, 10),
	)
}

func (f *Controller) MessageUpdated(message *models.ChannelMessage) error {
	objectID := strconv.FormatInt(message.Id, 10)
	channelId := strconv.FormatInt(message.InitialChannelId, 10)

	return f.partialUpdate(IndexMessages, map[string]interface{}{
		"objectID": objectID,
		"body":     message.Body,
		"_tags": map[string]interface{}{
			"_operation": "AddUnique",
			"value":      channelId,
		},
	})
}
