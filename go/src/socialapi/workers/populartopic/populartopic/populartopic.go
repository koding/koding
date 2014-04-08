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

func (t *PopularTopicsController) DefaultErrHandler(delivery amqp.Delivery, err error) {
	t.log.Error("an error occured putting message back to queue", err)
	// multiple false
	// reque true
	delivery.Nack(false, true)
}

func NewPopularTopicsController(log logging.Logger, redis *redis.RedisSession) *PopularTopicsController {
	ffc := &PopularTopicsController{
		log:   log,
		redis: redis,
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

	if cml.ChannelId == 0 {
		f.log.Error("ChannelId is not set for Channel Message List id: %d Deleting from rabbitmq", cml.Id)
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

	_, err = f.redis.SortedSetIncrBy(GetWeeklyKey(c, data), 1, data.MessageId)
	if err != nil {
		return err
	}

	_, err = f.redis.SortedSetIncrBy(GetMonthlyKey(c, data), 1, data.MessageId)
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

func GetRedisPrefix() string {
	return config.Get().Environment
}

func prepareKey(group, statisticName string, year, dateNumber int) string {
	return fmt.Sprintf(
		"%s:%s:%d:%s:%d",
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
		_, weekNumber = time.Now().ISOWeek()
		year, _, _ = time.Now().UTC().Date()
	}

	return prepareKey(c.GroupName, "weekly", year, weekNumber)
}

func GetMonthlyKey(c *models.Channel, cml *models.ChannelMessageList) string {
	var month time.Month
	year := 2014

	if !cml.AddedAt.IsZero() {
		year, month, _ = cml.AddedAt.UTC().Date()
	} else {
		year, month, _ = time.Now().UTC().Date()
	}

	return prepareKey(c.GroupName, "monthly", year, int(month))
}

func mapMessage(data []byte) (*models.ChannelMessageList, error) {
	cm := models.NewChannelMessageList()
	if err := json.Unmarshal(data, cm); err != nil {
		return nil, err
	}

	return cm, nil
}

func (f *PopularTopicsController) isEligible(c *models.Channel) bool {
	return true
	if c.TypeConstant != models.Channel_TYPE_TOPIC {
		return false
	}

	return true
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
