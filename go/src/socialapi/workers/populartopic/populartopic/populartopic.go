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

type Action func(*Controller, *models.ChannelMessageList) error

type Controller struct {
	routes map[string]Action
	log    logging.Logger
	redis  *redis.RedisSession
}

func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		t.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)
		return true
	}

	t.log.Error("an error occured putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func New(log logging.Logger, redis *redis.RedisSession) *Controller {
	ffc := &Controller{
		log:   log,
		redis: redis,
	}

	routes := map[string]Action{
		"api.channel_message_list_created": (*Controller).MessageSaved,
		"api.channel_message_list_deleted": (*Controller).MessageDeleted,
	}

	ffc.routes = routes
	return ffc
}

func (f *Controller) HandleEvent(event string, data []byte) error {
	f.log.Debug("New Event Received %s", event)
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

func (f *Controller) MessageSaved(data *models.ChannelMessageList) error {
	return f.handleMessageEvents(data, 1)
}

func (f *Controller) MessageDeleted(data *models.ChannelMessageList) error {
	return f.handleMessageEvents(data, -1)
}

func (f *Controller) handleMessageEvents(data *models.ChannelMessageList, increment int) error {
	c, err := models.ChannelById(data.ChannelId)
	if err != nil {
		return err
	}

	if !f.isEligible(c) {
		f.log.Info("Not eligible Channel Id:%d", c.Id)
		return nil
	}

	_, err = f.redis.SortedSetIncrBy(GetDailyKey(c, data), increment, data.ChannelId)
	if err != nil {
		return err
	}

	_, err = f.redis.SortedSetIncrBy(GetWeeklyKey(c, data), increment, data.ChannelId)
	if err != nil {
		return err
	}

	_, err = f.redis.SortedSetIncrBy(GetMonthlyKey(c, data), increment, data.ChannelId)
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

func GetDailyKey(c *models.Channel, cml *models.ChannelMessageList) string {
	day := 0
	year := 2014

	if !cml.AddedAt.IsZero() {
		day = cml.AddedAt.UTC().YearDay()
		year, _, _ = cml.AddedAt.UTC().Date()
	} else {
		now := time.Now().UTC()
		day = now.YearDay()
		year, _, _ = now.Date()
	}

	return PreparePopularTopicKey(c.GroupName, "daily", year, day)
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

func (f *Controller) isEligible(c *models.Channel) bool {
	if c.MetaBits.Is(models.Troll) {
		return false
	}

	if c.TypeConstant != models.Channel_TYPE_TOPIC {
		return false
	}

	return true
}
