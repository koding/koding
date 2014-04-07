package populartopic

import (
	"encoding/json"
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"time"

	"github.com/koding/logging"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
)

var (
	PopularTopicKey = "populartopic"
)

type Action func(*PopularTopicsController, *models.ChannelMessageList) error

type PopularTopicsController struct {
	routes map[string]Action
	log    logging.Logger
}

func (t *PopularTopicsController) DefaultErrHandler(delivery amqp.Delivery, err error) {
	t.log.Error("an error occured putting message back to queue", err)
	// multiple false
	// reque true
	delivery.Nack(false, true)
}

func NewPopularTopicsController(log logging.Logger) *PopularTopicsController {
	ffc := &PopularTopicsController{
		log: log,
	}

	routes := map[string]Action{
		"channel_message_list_created": (*PopularTopicsController).MessageSaved,
		"channel_message_list_deleted": (*PopularTopicsController).MessageDeleted,
	}

	ffc.routes = routes

	return ffc
}

func (f *PopularTopicsController) HandleEvent(event string, data []byte) error {
	f.log.Debug("New Event Recieved %s", event)
	handler, ok := f.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	cml, err := mapMessage(data)
	if err != nil {
		return err
	}

	res, err := f.isEligible(cml)
	if err != nil {
		return err
	}

	// filter messages here
	if !res {
		return nil
	}

	return handler(f, cml)
}

func (f *PopularTopicsController) MessageSaved(data *models.ChannelMessageList) error {
	return nil
}

func (f *PopularTopicsController) MessageDeleted(data *models.ChannelMessageList) error {
	return nil
}

func prepareKey(dateKey string) string {
	return fmt.Sprintf(
		"%s-%s-%s",
		config.Get().Environment,
		PopularTopicKey,
		dateKey,
	)
}

func GetWeeklyKey(cml *ChannelMessageList) string {
	weekNumber := 0
	year := 2014

	if cml.AddedAt != nil {
		_, weekNumber = cml.AddedAt.ISOWeek()
		year, _, _ = cml.AddedAt.UTC().Date()
	} else {
		// no need to convert it to UTC
		_, weekNumber = time.Now.ISOWeek()
		year, _, _ = time.Now().UTC().Date()

	}

	dateKey := fmt.Sprintf(
		"%s-%d-%d",
		"weekly",
		year,
		weekNumber,
	)
	return prepareKey(dateKey)
}

func GetMonthlyKey(cml *ChannelMessageList) string {
	month := 0
	year := 2014

	if cml.AddedAt != nil {
		year, month, _ = cml.AddedAt.UTC().Date()
	} else {
		year, month, _ = time.Now().UTC().Date()
	}

	dateKey := fmt.Sprintf(
		"%s-%d-%d",
		"monthly",
		year,
		month,
	)
	return prepareKey(dateKey)
}

// func (f *PopularTopicsController) MessageUpdated(data *models.ChannelMessage) error {
// 	f.log.Debug("udpate message %s", data.Id)
// 	// fetch message's current topics from the db
// 	channels, err := fetchMessageChannels(data.Id)
// 	if err != nil {
// 		return err
// 	}

// 	// get current topics from
// 	topics := extractTopics(data.Body)
// 	if topics == nil {
// 		return nil
// 	}

// 	// if message and the topics dont have any item, we can safely return
// 	if len(channels) == 0 && len(topics) == 0 {
// 		return nil
// 	}

// 	res := getTopicDiff(channels, topics)

// 	// add messages
// 	if len(res["added"]) > 0 {
// 		initialChannel, err := fetchChannel(data.InitialChannelId)
// 		if err != nil {
// 			return err
// 		}

// 		if err := ensureChannelMessages(initialChannel, data, res["added"]); err != nil {
// 			return err
// 		}
// 	}

// 	// delete messages
// 	if len(res["deleted"]) > 0 {
// 		if err := deleteChannelMessages(channels, data, res["deleted"]); err != nil {
// 			return err
// 		}
// 	}

// 	return nil
// }

// func deleteChannelMessages(channels []models.Channel, data *models.ChannelMessage, toBeDeletedTopics []string) error {
// 	for _, channel := range channels {
// 		for _, topic := range toBeDeletedTopics {
// 			if channel.Name != topic {
// 				continue
// 			}

// 			cml := models.NewChannelMessageList()
// 			selector := map[string]interface{}{
// 				"message_id": data.Id,
// 				"channel_id": channel.Id,
// 			}

// 			if err := cml.DeleteMessagesBySelector(selector); err != nil {
// 				return err
// 			}
// 		}
// 	}
// 	return nil
// }

// func fetchMessageChannels(messageId int64) ([]models.Channel, error) {
// 	cml := models.NewChannelMessageList()
// 	return cml.FetchMessageChannels(messageId)
// }

// func getTopicDiff(channels []models.Channel, topics []string) map[string][]string {
// 	res := make(map[string][]string)

// 	// aggregate all channel names into map
// 	channelNames := map[string]struct{}{}
// 	for _, channel := range channels {
// 		channelNames[channel.Name] = struct{}{}
// 	}

// 	// range over new topics, bacause we are gonna remove
// 	// unused channels
// 	for _, topic := range topics {
// 		found := false
// 		for channelName := range channelNames {
// 			if channelName == topic {
// 				found = true
// 			}
// 		}
// 		if !found {
// 			res["added"] = append(res["added"], topic)
// 		} else {
// 			// if we have topic in channels
// 			// do remove it because at the end we are gonna mark
// 			// channels as deleted which are still in channelNames
// 			delete(channelNames, topic)
// 		}
// 	}
// 	// flatten the deleted channel names
// 	for channelName := range channelNames {
// 		res["deleted"] = append(res["deleted"], channelName)
// 	}

// 	return res
// }

// func (f *PopularTopicsController) MessageDeleted(data *models.ChannelMessage) error {
// 	cml := models.NewChannelMessageList()
// 	selector := map[string]interface{}{
// 		"message_id": data.Id,
// 	}

// 	if err := cml.DeleteMessagesBySelector(selector); err != nil {
// 		return err
// 	}
// 	return nil
// }

func mapMessage(data []byte) (*models.ChannelMessageList, error) {
	cm := models.NewChannelMessageList()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

func (f *PopularTopicsController) isEligible(cml *models.ChannelMessageList) (bool, error) {
	if cml.ChannelId == 0 {
		f.log.Notice("ChannelId is not set for Channel Message List id: %d", cml.Id)
		return false, nil
	}

	c, err := fetchChannel(cml.ChannelId)
	if err != nil {
		return false, err
	}

	if c.TypeConstant != models.Channel_TYPE_TOPIC {
		return false, nil
	}

	return true, nil
}

// todo add caching here
func fetchChannel(channelId int64) (*models.Channel, error) {
	c := models.NewChannel()
	c.Id = channelId
	if err := c.Fetch(); err != nil {
		return nil, err
	}

	return c, nil
}

// // todo add caching here
// func fetchTopicChannel(groupName, channelName string) (*models.Channel, error) {
// 	c := models.NewChannel()

// 	selector := map[string]interface{}{
// 		"group_name":    groupName,
// 		"name":          channelName,
// 		"type_constant": models.Channel_TYPE_TOPIC,
// 	}

// 	err := c.One(bongo.NewQS(selector))
// 	if err != nil {
// 		return nil, err
// 	}

// 	return c, nil
// }

// func createTopicChannel(creatorId int64, groupName, channelName, privacy string) (*models.Channel, error) {
// 	c := models.NewChannel()
// 	c.Name = channelName
// 	c.CreatorId = creatorId
// 	c.GroupName = groupName
// 	c.Purpose = fmt.Sprintf("Channel for %s topic", channelName)
// 	c.TypeConstant = models.Channel_TYPE_TOPIC
// 	c.PrivacyConstant = privacy
// 	if err := c.Create(); err != nil {
// 		return nil, err
// 	}

// 	return c, nil
// }
