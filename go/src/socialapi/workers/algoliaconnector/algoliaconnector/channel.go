package algoliaconnector

import (
	"socialapi/models"
	"strconv"
)

// ChannelCreated handles the channel create events, for now only handles the
// channels that are topic channels,
func (f *Controller) ChannelCreated(data *models.Channel) error {
	if data.TypeConstant != models.Channel_TYPE_TOPIC {
		return nil
	}

	return f.insert(IndexTopics, map[string]interface{}{
		"objectID": strconv.FormatInt(data.Id, 10),
		"name":     data.Name,
		"purpose":  data.Purpose,
	})
}

// ChannelUpdated handles the channel update events, for now only handles the
// channels that are topic channels, we can link channels together in any point
// of time, after linking, leaf channel is removed from search engine. But it is
// still searchable via its root channel, because we are adding it as synonym to
// the root of it
func (f *Controller) ChannelUpdated(data *models.Channel) error {
	if data.TypeConstant != models.Channel_TYPE_LINKED_TOPIC {
		f.log.Debug("unsuported channel for topic update type: %s id: %d", data.TypeConstant, data.Id)
		return nil
	}

	return f.delete(IndexTopics, strconv.FormatInt(data.Id, 10))
}
