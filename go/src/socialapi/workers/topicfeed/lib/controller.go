package followingfeed

import (
	"encoding/json"
	"errors"
	"fmt"
	"koding/tools/logger"
	"socialapi/models"

	verbalexpressions "github.com/VerbalExpressions/GoVerbalExpressions"
	"github.com/jinzhu/gorm"
)

// s := "naber #foo hede #bar dede gel # baz #123 #-`3sdf"
// will find [foo, bar, 123]
// will not find [' baz', '-`3sdf']
// here is the regex -> (?m)(?:#)(\w+)(?: )
var topicRegex = verbalexpressions.New().
	Find("#").
	BeginCapture().
	Word().
	EndCapture().
	Find(" ").
	Regex()

type Action func(*TopicFeedController, *models.ChannelMessage) error

type TopicFeedController struct {
	routes map[string]Action
	log    logger.Log
}

var HandlerNotFoundErr = errors.New("Handler Not Found")

func NewTopicFeedController(log logger.Log) *TopicFeedController {
	// s := "naber #foo hede #bar dede gel # baz #123 #-`3sdf"
	// res := topicRegex.FindAllStringSubmatch(s, -1)
	// fmt.Println("res", res)
	// fmt.Println("res", res[0][1])
	// fmt.Println("res", res[1][1])
	// fmt.Println(topicRegex.String())

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
		return HandlerNotFoundErr
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

	res := topicRegex.FindAllStringSubmatch(data.Body, -1)
	if len(res) == 0 {
		f.log.Debug("Message doesnt have any topic Body: %s", data.Body)
		return nil
	}

	c, err := fetchChannel(data.InitialChannelId)
	if err != nil {
		return err
	}

	topics := map[string]struct{}{}

	for _, ele := range res {
		topics[ele[1]] = struct{}{}
	}

	for topic := range topics {
		channelName := topic
		tc, err := fetchTopicChannel(c.Group, channelName)
		if err != nil && err != gorm.RecordNotFound {
			return err
		}

		if err == gorm.RecordNotFound {
			tc, err = createTopicChannel(data.AccountId, c.Group, channelName, c.Privacy)
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

func (f *TopicFeedController) MessageUpdated(data *models.ChannelMessage) error {
	fmt.Println("update", data.InitialChannelId)
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
				"mesage_id":  data.Id,
				"channel_id": channel.Id,
			}

			if err := cml.DeleteMessagesBySelector(selector); err != nil {
				return err
			}
		}
	}
	return nil
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
		"mesage_id": data.Id,
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

	if cm.Type != models.ChannelMessage_TYPE_POST {
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
		"group": groupName,
		"name":  channelName,
		"type":  models.Channel_TYPE_TOPIC,
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
	c.Group = groupName
	c.Purpose = fmt.Sprintf("Channel for %s topic", channelName)
	c.Type = models.Channel_TYPE_TOPIC
	c.Privacy = privacy
	if err := c.Create(); err != nil {
		return nil, err
	}

	return c, nil
}
