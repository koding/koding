package topicfeed

import (
	"encoding/json"
	"fmt"
	"socialapi/models"
	"github.com/koding/logging"
	"github.com/koding/worker"
	"github.com/streadway/amqp"

	verbalexpressions "github.com/VerbalExpressions/GoVerbalExpressions"
	"github.com/jinzhu/gorm"
)

// s := "naber #foo hede #bar dede gel # baz #123 #-`3sdf"
// will find [foo, bar, 123]
// will not find [' baz', '-`3sdf']
// here is the regex -> (?m)(?:#)(\w+)
var topicRegex = verbalexpressions.New().
	Find("#").
	BeginCapture().
	Word().
	EndCapture().
	Regex()

// extend this regex with https://github.com/twitter/twitter-text-rb/blob/eacf388136891eb316f1c110da8898efb8b54a38/lib/twitter-text/regex.rb
// to support all languages

type Action func(*TopicFeedController, *models.ChannelMessage) error

type TopicFeedController struct {
	routes map[string]Action
	log    logging.Logger
}

func (t *TopicFeedController) DefaultErrHandler(delivery amqp.Delivery, err error) {
	t.log.Error("an error occured %s, \n putting message back to queue", err)
	// multiple false
	// reque true
	delivery.Nack(false, true)
}

func NewTopicFeedController(log logging.Logger) *TopicFeedController {
	ffc := &TopicFeedController{
		log: log,
	}

	routes := map[string]Action{
		"channel_message_created": (*TopicFeedController).MessageSaved,
		"channel_message_update":  (*TopicFeedController).MessageUpdated,
		"channel_message_deleted": (*TopicFeedController).MessageDeleted,
	}

	ffc.routes = routes

	return ffc
}

func (f *TopicFeedController) HandleEvent(event string, data []byte) error {
	f.log.Debug("New Event Recieved %s", event)
	handler, ok := f.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	cm, err := mapMessage(data)
	if err != nil {
		return err
	}

	res, err := isEligible(cm)
	if err != nil {
		return err
	}

	if !res {
		return nil
	}

	return handler(f, cm)
}

func (f *TopicFeedController) MessageSaved(data *models.ChannelMessage) error {

	topics := extractTopics(data.Body)
	if len(topics) == 0 {
		return nil
	}

	c, err := fetchChannel(data.InitialChannelId)
	if err != nil {
		f.log.Error("Error on fetchChannel %d, %s", data.InitialChannelId, err)
		return err
	}

	return ensureChannelMessages(c, data, topics)
}

func ensureChannelMessages(parentChannel *models.Channel, data *models.ChannelMessage, topics []string) error {
	for _, topic := range topics {
		tc, err := fetchTopicChannel(parentChannel.GroupName, topic)
		if err != nil && err != gorm.RecordNotFound {
			return err
		}

		if err == gorm.RecordNotFound {
			tc, err = createTopicChannel(data.AccountId, parentChannel.GroupName, topic, parentChannel.PrivacyConstant)
			if err != nil {
				return err
			}
		}

		_, err = tc.AddMessage(data.Id)
		if err != nil {
			return err
		}
	}

	return nil
}

func extractTopics(body string) []string {
	flattened := make([]string, 0)

	res := topicRegex.FindAllStringSubmatch(body, -1)
	if len(res) == 0 {
		return flattened
	}

	topics := map[string]struct{}{}
	// remove duplicate tag usages
	for _, ele := range res {
		topics[ele[1]] = struct{}{}
	}

	for topic := range topics {
		flattened = append(flattened, topic)
	}

	return flattened
}

func (f *TopicFeedController) MessageUpdated(data *models.ChannelMessage) error {
	f.log.Debug("udpate message %s", data.Id)
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

	res := getTopicDiff(channels, topics)

	// add messages
	if len(res["added"]) > 0 {
		initialChannel, err := fetchChannel(data.InitialChannelId)
		if err != nil {
			return err
		}

		if err := ensureChannelMessages(initialChannel, data, res["added"]); err != nil {
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

func getTopicDiff(channels []models.Channel, topics []string) map[string][]string {
	res := make(map[string][]string)

	// aggregate all channel names into map
	channelNames := map[string]struct{}{}
	for _, channel := range channels {
		channelNames[channel.Name] = struct{}{}
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

func (f *TopicFeedController) MessageDeleted(data *models.ChannelMessage) error {
	cml := models.NewChannelMessageList()
	selector := map[string]interface{}{
		"message_id": data.Id,
	}

	if err := cml.DeleteMessagesBySelector(selector); err != nil {
		return err
	}
	return nil
}

func mapMessage(data []byte) (*models.ChannelMessage, error) {
	cm := models.NewChannelMessage()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
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
func fetchChannel(channelId int64) (*models.Channel, error) {
	c := models.NewChannel()
	c.Id = channelId
	// todo - fetch only name here
	if err := c.Fetch(); err != nil {
		return nil, err
	}

	return c, nil
}

// todo add caching here
func fetchTopicChannel(groupName, channelName string) (*models.Channel, error) {
	c := models.NewChannel()

	selector := map[string]interface{}{
		"group_name":    groupName,
		"name":          channelName,
		"type_constant": models.Channel_TYPE_TOPIC,
	}

	err := c.One(selector)
	if err != nil {
		return nil, err
	}

	return c, nil
}

func createTopicChannel(creatorId int64, groupName, channelName, privacy string) (*models.Channel, error) {
	c := models.NewChannel()
	c.Name = channelName
	c.CreatorId = creatorId
	c.GroupName = groupName
	c.Purpose = fmt.Sprintf("Channel for %s topic", channelName)
	c.TypeConstant = models.Channel_TYPE_TOPIC
	c.PrivacyConstant = privacy
	if err := c.Create(); err != nil {
		return nil, err
	}

	return c, nil
}
