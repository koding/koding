package populartopic

import (
	"encoding/json"
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"time"

	"github.com/koding/logging"
	"github.com/koding/redis"
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
	redis  *redis.RedisSession
}

func (t *PopularTopicsController) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		t.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)
		return true
	}

	t.log.Error("an error occured putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func NewPopularTopicsController(log logging.Logger, redis *redis.RedisSession) *PopularTopicsController {
	ffc := &PopularTopicsController{
		log:   log,
		redis: redis,
	}

	routes := map[string]Action{
		"api.channel_message_list_created": (*PopularTopicsController).MessageSaved,
		"api.channel_message_list_deleted": (*PopularTopicsController).MessageDeleted,
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

	if cml.ChannelId == 0 {
		f.log.Error(fmt.Sprintf("ChannelId is not set for Channel Message List id: %d Deleting from rabbitmq", cml.Id))
		return nil
	}

	return handler(f, cml)
}

func (f *PopularTopicsController) MessageSaved(data *models.ChannelMessageList) error {
	c, err := fetchChannel(data.ChannelId)
	if err != nil {
		return err
	}

	if !f.isEligible(c) {
		f.log.Info("Not eligible Channel Id:%d", c.Id)
		return nil
	}

	_, err = f.redis.SortedSetIncrBy(GetWeeklyKey(c, data), 1, data.ChannelId)
	if err != nil {
		return err
	}

	_, err = f.redis.SortedSetIncrBy(GetMonthlyKey(c, data), 1, data.ChannelId)
	if err != nil {
		return err
	}

	return nil
}

func (f *PopularTopicsController) MessageDeleted(data *models.ChannelMessageList) error {
	c, err := fetchChannel(data.ChannelId)
	if err != nil {
		return err
	}

	if !f.isEligible(c) {
		f.log.Info("Not eligible Channel Id:%d", c.Id)
		return nil
	}

	_, err = f.redis.SortedSetIncrBy(GetWeeklyKey(c, data), -1, data.MessageId)
	if err != nil {
		return err
	}

	_, err = f.redis.SortedSetIncrBy(GetMonthlyKey(c, data), -1, data.MessageId)
	if err != nil {
		return err
	}

	return nil
}

func PreparePopularTopicKey(group, statisticName string, year, dateNumber int) string {
	return fmt.Sprintf(
		"%s:%s:%s:%d:%s:%d",
		config.Get().Environment,
		group,
		PopularTopicKey,
		year,
		statisticName,
		dateNumber,
	)
}

func GetWeeklyKey(c *models.Channel, cml *models.ChannelMessageList) string {
	weekNumber := 0
	year := 2014

	if !cml.AddedAt.IsZero() {
		_, weekNumber = cml.AddedAt.ISOWeek()
		year, _, _ = cml.AddedAt.UTC().Date()
	} else {
		// no need to convert it to UTC
		now := time.Now()
		_, weekNumber = now.ISOWeek()
		year, _, _ = now.UTC().Date()
	}

	return PreparePopularTopicKey(c.GroupName, "weekly", year, weekNumber)
}

func GetMonthlyKey(c *models.Channel, cml *models.ChannelMessageList) string {
	var month time.Month
	year := 2014

	if !cml.AddedAt.IsZero() {
		year, month, _ = cml.AddedAt.UTC().Date()
	} else {
		year, month, _ = time.Now().UTC().Date()
	}

	return PreparePopularTopicKey(c.GroupName, "monthly", year, int(month))
}

func mapMessage(data []byte) (*models.ChannelMessageList, error) {
	cm := models.NewChannelMessageList()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

func (f *PopularTopicsController) isEligible(c *models.Channel) bool {
	if c.TypeConstant != models.Channel_TYPE_TOPIC {
		return false
	}

	return true
}

// todo add caching here
func fetchChannel(channelId int64) (*models.Channel, error) {
	c := models.NewChannel()
	if err := c.ById(channelId); err != nil {
		return nil, err
	}

	return c, nil
}
