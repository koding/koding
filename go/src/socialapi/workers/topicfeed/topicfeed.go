package topicfeed

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/kylemcc/twitter-text-go/extract"
	"github.com/streadway/amqp"
)

type Controller struct {
	log    logging.Logger
	config *config.Config
}

func New(log logging.Logger, config *config.Config) *Controller {
	return &Controller{
		log:    log,
		config: config,
	}
}

func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		t.log.Error("Redelivered message gave error again, putting to maintenance queue: %s", err)
		delivery.Ack(false)
		return true
	}

	t.log.Error("an error occurred putting message back to queue: %s", err)
	delivery.Nack(false, true)
	return false
}

func (f *Controller) MessageSaved(data *models.ChannelMessage) error {
	if res, _ := isEligible(data); !res {
		return nil
	}

	topics := extractTopics(data.Body)
	if len(topics) == 0 {
		return nil
	}

	c, err := models.Cache.Channel.ById(data.InitialChannelId)
	if err != nil {
		f.log.Error("Error on models.Cache.Channel.ById", data.InitialChannelId, err)
		return err
	}

	return f.ensureChannelMessages(c, data, topics)
}

func (f *Controller) ensureChannelMessages(parentChannel *models.Channel, data *models.ChannelMessage, topics []string) error {
	for _, topic := range topics {
		tc, err := f.fetchTopicChannel(parentChannel.GroupName, topic)
		if err != nil && err != bongo.RecordNotFound {
			return err
		}

		if err == bongo.RecordNotFound {
			tc, err = f.createTopicChannel(data.AccountId, parentChannel.GroupName, topic, parentChannel.PrivacyConstant)
			if err != nil {
				return err
			}
		}

		// message list relationship is already created in Message.Create
		if tc.Id == data.InitialChannelId {
			continue
		}

		_, err = tc.EnsureMessage(data, true)
		// safely skip
		if err == models.ErrMessageAlreadyInTheChannel {
			continue
		}

		if err != nil {
			return err
		}
	}

	return nil
}

func extractTopics(body string) []string {
	flattened := make([]string, 0)

	// extract twitter style hashtags
	res := extract.ExtractHashtags(body)
	if res == nil {
		return flattened
	}

	topics := map[string]struct{}{}
	// remove duplicate tag usages
	for _, e := range res {
		if hashTag, ok := e.Hashtag(); ok {
			topics[hashTag] = struct{}{}
		}
	}

	// filter unwanted topics
	topics = filterTopics(topics)

	for topic := range topics {
		flattened = append(flattened, topic)
	}

	return flattened
}

func filterTopics(topics map[string]struct{}) map[string]struct{} {
	blacklistedTopics := []string{
		// public topic is used for group channel, if user adds `public` tag
		// into the message, do not try to add it to the group channel again
		"public",
	}

	filteredTopics := make(map[string]struct{})

	for topic, _ := range topics {
		blacklisted := false
		// check if the topic is in blacklisted topics
		for _, blacklistedTopic := range blacklistedTopics {
			if topic == blacklistedTopic {
				blacklisted = true
				break
			}
		}

		// merge -not blacklisted- topics
		if !blacklisted {
			filteredTopics[topic] = struct{}{}
		}
	}

	return filteredTopics

}
func (f *Controller) MessageUpdated(data *models.ChannelMessage) error {
	if res, _ := isEligible(data); !res {
		return nil
	}

	f.log.Debug("update message %s", data.Id)
	// fetch message's current topics from the db
	channels, err := fetchMessageChannels(data.Id)
	if err != nil {
		return err
	}

	// get current topics from
	topics := extractTopics(data.Body)
	if topics == nil {
		return nil
	}

	// if message and the topics dont have any item, we can safely return
	if len(channels) == 0 && len(topics) == 0 {
		return nil
	}

	excludedChannelId := data.InitialChannelId

	res := getTopicDiff(channels, topics, excludedChannelId)

	// add messages
	if len(res["added"]) > 0 {
		initialChannel, err := models.Cache.Channel.ById(data.InitialChannelId)
		if err != nil {
			return err
		}

		if err := f.ensureChannelMessages(initialChannel, data, res["added"]); err != nil {
			return err
		}
	}

	// delete messages
	if len(res["deleted"]) > 0 {
		if err := deleteChannelMessages(channels, data, res["deleted"]); err != nil {
			return err
		}
	}

	return nil
}

func deleteChannelMessages(channels []models.Channel, data *models.ChannelMessage, toBeDeletedTopics []string) error {
	for _, channel := range channels {
		for _, topic := range toBeDeletedTopics {
			if channel.Name != topic {
				continue
			}

			cml := models.NewChannelMessageList()
			selector := map[string]interface{}{
				"message_id": data.Id,
				"channel_id": channel.Id,
			}

			if err := cml.DeleteMessagesBySelector(selector); err != nil {
				return err
			}
		}
	}
	return nil
}

func fetchMessageChannels(messageId int64) ([]models.Channel, error) {
	cml := models.NewChannelMessageList()
	return cml.FetchMessageChannels(messageId)
}

func getTopicDiff(channels []models.Channel, topics []string, excludedChannelId int64) map[string][]string {
	res := make(map[string][]string)

	// aggregate all channel names into map
	channelNames := map[string]struct{}{}
	for _, channel := range channels {
		if excludedChannelId != channel.GetId() && channel.TypeConstant != models.Channel_TYPE_GROUP {
			channelNames[channel.Name] = struct{}{}
		}
	}

	// range over new topics, bacause we are gonna remove
	// unused channels
	for _, topic := range topics {
		found := false
		for channelName := range channelNames {
			if channelName == topic {
				found = true
			}
		}
		if !found {
			res["added"] = append(res["added"], topic)
		} else {
			// if we have topic in channels
			// do remove it because at the end we are gonna mark
			// channels as deleted which are still in channelNames
			delete(channelNames, topic)
		}
	}
	// flatten the deleted channel names
	for channelName := range channelNames {
		res["deleted"] = append(res["deleted"], channelName)
	}

	return res
}

func (f *Controller) MessageDeleted(data *models.ChannelMessage) error {
	if res, _ := isEligible(data); !res {
		return nil
	}

	cml := models.NewChannelMessageList()
	selector := map[string]interface{}{
		"message_id": data.Id,
	}

	if err := cml.DeleteMessagesBySelector(selector); err != nil {
		return err
	}
	return nil
}

func isEligible(cm *models.ChannelMessage) (bool, error) {
	if cm.InitialChannelId == 0 {
		return false, nil
	}

	if cm.TypeConstant != models.ChannelMessage_TYPE_POST {
		return false, nil
	}

	return true, nil
}

// todo add caching here
func (f *Controller) fetchTopicChannel(groupName, channelName string) (*models.Channel, error) {
	c := models.NewChannel()

	topics := make([]models.Channel, 0)
	err := bongo.B.DB.Table(c.BongoName()).
		Where("group_name = ?", groupName).
		Where("name = ?", channelName).
		Where("type_constant IN (?)", []string{
		models.Channel_TYPE_TOPIC,
		models.Channel_TYPE_LINKED_TOPIC,
	}).
		Order("id asc").
		Find(&topics).Error

	if err != nil {
		return nil, err
	}
	var channel *models.Channel

	switch len(topics) {
	case 0:
		return nil, bongo.RecordNotFound
	case 1:
		channel = &(topics[0])
	case 2:
		for _, ch := range topics {
			if ch.TypeConstant == models.Channel_TYPE_LINKED_TOPIC {
				channel = &ch
				f.log.Critical(
					"duplicate channel content %s, %s",
					groupName,
					channelName,
				)
				break
			}
		}
	default:
		return nil, fmt.Errorf(
			"should not happen while fetching channel, groupName: %s, channelName: %s",
			groupName,
			channelName,
		)
	}

	if channel == nil {
		f.log.Critical(
			"should not happen while fetching channel %s, %s",
			groupName,
			channelName,
		)
		return nil, bongo.RecordNotFound
	}

	// if it a normal channel just return it
	if channel.TypeConstant != models.Channel_TYPE_LINKED_TOPIC {
		return channel, nil
	}

	return channel.FetchRoot()
}

func (f *Controller) createTopicChannel(creatorId int64, groupName, channelName, privacy string) (*models.Channel, error) {
	c := models.NewChannel()
	c.Name = channelName
	c.CreatorId = creatorId
	c.GroupName = groupName
	c.Purpose = fmt.Sprintf("Channel for %s topic", channelName)
	c.TypeConstant = models.Channel_TYPE_TOPIC
	c.PrivacyConstant = privacy
	// add moderation needed flag only for koding group
	// and if feature is not disabled
	if !f.config.DisabledFeatures.Moderation && c.GroupName == models.Channel_KODING_NAME {
		// newly created channels need moderation
		c.MetaBits.Mark(models.NeedsModeration)
	}
	err := c.Create()
	if err == nil {
		return c, nil
	}

	// same topic can be created in parallel
	if models.IsUniqueConstraintError(err) {
		// just fetch the topic from db
		c2 := models.NewChannel()
		err = c2.One(&bongo.Query{
			Selector: map[string]interface{}{
				"name":             channelName,
				"group_name":       groupName,
				"type_constant":    models.Channel_TYPE_TOPIC,
				"privacy_constant": privacy,
			},
		})
		if err != nil {
			return nil, err
		}

		return c2, nil
	}

	return nil, err
}
