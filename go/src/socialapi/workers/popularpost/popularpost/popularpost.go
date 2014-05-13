package popularpost

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/helper"
	"time"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/koding/worker"
	"github.com/streadway/amqp"
)

var (
	PopularPostKey = "popularpost"
)

type Action func(*PopularPostController, []byte) error

type PopularPostController struct {
	routes map[string]Action
	log    logging.Logger
	redis  *redis.RedisSession
}

func (t *PopularPostController) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		t.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)
		return true
	}

	t.log.Error("an error occured putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func NewPopularPostController(log logging.Logger, redis *redis.RedisSession) *PopularPostController {
	ppc := &PopularPostController{
		log:   log,
		redis: redis,
	}

	routes := map[string]Action{
		// "api.channel_message_deleted": (*PopularPostController).MessageDeleted,

		"api.interaction_created": (*PopularPostController).InteractionSaved,
		"api.interaction_deleted": (*PopularPostController).InteractionDeleted,
	}

	ppc.routes = routes
	return ppc
}

func (f *PopularPostController) HandleEvent(event string, data []byte) error {
	f.log.Debug("New Event Recieved %s", event)
	handler, ok := f.routes[event]
	if !ok {
		return worker.HandlerNotFoundErr
	}

	f.log.Critical("oldumu%s", string(data))

	errr := handler(f, data)
	if errr != nil {
		f.log.Critical("oldumu%s", errr.Error())
	}
	return errr
}

func (f *PopularPostController) InteractionSaved(data []byte) error {
	return f.handleInteractionEvent("InteractionAdded", data)
}

func (f *PopularPostController) InteractionDeleted(data []byte) error {
	return f.handleInteractionEvent("InteractionRemoved", data)
}

func (f *PopularPostController) handleInteractionEvent(eventName string, data []byte) error {
	i, err := helper.MapToInteraction(data)
	if err != nil {
		return err
	}

	cm := models.NewChannelMessage()
	if err := cm.ById(i.MessageId); err != nil {
		return err
	}

	c, err := models.ChannelById(cm.InitialChannelId)
	if err != nil {
		return err
	}

	if !f.isEligible(c, cm) {
		f.log.Error("Not eligible Interaction Id:%d", i.Id)
		return nil
	}

	_, err = f.redis.SortedSetIncrBy(GetDailyKey(c, cm, i), 1, i.MessageId)
	if err != nil {
		return err
	}

	_, err = f.redis.SortedSetIncrBy(GetWeeklyKey(c, cm, i), 1, i.MessageId)
	if err != nil {
		return err
	}

	_, err = f.redis.SortedSetIncrBy(GetMonthlyKey(c, cm, i), 1, i.MessageId)
	if err != nil {
		return err
	}

	return nil

}

func (f *PopularPostController) isEligible(c *models.Channel, cm *models.ChannelMessage) bool {
	// to-do do not forget to remove return true
	return true

	if c.PrivacyConstant != models.Channel_PRIVACY_PUBLIC {
		return false
	}

	if cm.TypeConstant != models.ChannelMessage_TYPE_POST {
		return false
	}

	return true
}

func PreparePopularPostKey(group, channelName, statisticName string, year, dateNumber int) string {
	return fmt.Sprintf(
		"%s:%s:%s:%s:%d:%s:%d",
		config.Get().Environment,
		group,
		PopularPostKey,
		channelName,
		year,
		statisticName,
		dateNumber,
	)
}

func GetDailyKey(c *models.Channel, cm *models.ChannelMessage, i *models.Interaction) string {
	day := 0
	year := 2014

	if !i.CreatedAt.IsZero() {
		day = i.CreatedAt.UTC().YearDay()
		year, _, _ = i.CreatedAt.UTC().Date()
	} else {
		// no need to convert it to UTC
		now := time.Now().UTC()
		day = now.YearDay()
		year, _, _ = now.Date()
	}

	return PreparePopularPostKey(c.GroupName, c.Name, "daily", year, day)
}

func GetWeeklyKey(c *models.Channel, cm *models.ChannelMessage, i *models.Interaction) string {
	weekNumber := 0
	year := 2014

	if !i.CreatedAt.IsZero() {
		_, weekNumber = i.CreatedAt.ISOWeek()
		year, _, _ = i.CreatedAt.UTC().Date()
	} else {
		// no need to convert it to UTC
		now := time.Now()
		_, weekNumber = now.ISOWeek()
		year, _, _ = now.UTC().Date()
	}

	return PreparePopularPostKey(c.GroupName, c.Name, "weekly", year, weekNumber)
}

func GetMonthlyKey(c *models.Channel, cm *models.ChannelMessage, i *models.Interaction) string {
	var month time.Month
	year := 2014

	if !i.CreatedAt.IsZero() {
		year, month, _ = i.CreatedAt.UTC().Date()
	} else {
		year, month, _ = time.Now().UTC().Date()
	}

	return PreparePopularPostKey(c.GroupName, c.Name, "monthly", year, int(month))
}
