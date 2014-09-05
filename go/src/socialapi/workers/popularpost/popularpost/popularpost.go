package popularpost

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"time"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/streadway/amqp"
)

var (
	PopularPostKeyName = "popularpost"
)

type Controller struct {
	log   logging.Logger
	redis *redis.RedisSession
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
	return &Controller{
		log:   log,
		redis: redis,
	}
}

func (f *Controller) InteractionSaved(i *models.Interaction) error {
	return f.handleInteraction(1, i)
}

func (f *Controller) InteractionDeleted(i *models.Interaction) error {
	return f.handleInteraction(-1, i)
}

func (f *Controller) handleInteraction(incrementCount int, i *models.Interaction) error {
	cm, err := models.ChannelMessageById(i.MessageId)
	if err != nil {
		return err
	}

	c, err := models.ChannelById(cm.InitialChannelId)
	if err != nil {
		return err
	}

	if notEligibleForPopularPost(c, cm) {
		f.log.Error(fmt.Sprintf("Not eligible Interaction Id:%d", i.Id))
		return nil
	}

	if createdMoreThan7DaysAgo(cm.CreatedAt) {
		f.log.Debug(fmt.Sprintf("Post created more than 7 days ago: %v, %v", i.Id, i.CreatedAt))
		return nil
	}

	err = f.saveToDailyBucket(c, cm, i, incrementCount)
	if err != nil {
		return err
	}

	err = f.saveToSevenDayBucket(c, cm, i, incrementCount)
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) saveToDailyBucket(c *models.Channel, cm *models.ChannelMessage, i *models.Interaction, incrementCount int) error {
	key := getDailyKey(c, cm.CreatedAt)
	_, err := f.redis.SortedSetIncrBy(key, incrementCount, cm.Id)

	return err
}

func (f *Controller) saveToSevenDayBucket(c *models.Channel, cm *models.ChannelMessage, i *models.Interaction, incrementCount int) error {
	key := getSevenDayKey(c, cm)
	from := getStartOfDay(cm.CreatedAt)

	exists := f.redis.Exists(key)
	if exists {
		_, err := f.redis.SortedSetIncrBy(key, incrementCount, cm.Id)
		return err
	}

	err := f.createSevenDayCombinedBucket(c, cm, key, from)
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) createSevenDayCombinedBucket(c *models.Channel, cm *models.ChannelMessage, key string, from time.Time) error {
	keys, weights := []interface{}{}, []interface{}{}
	aggregate := "SUM"
	from = getStartOfDay(from)

	for i := 0; i <= 6; i++ {
		currentDate := getXDaysAgo(from, i)
		key := getDailyKey(c, currentDate)
		keys = append(keys, key)

		// add by 1 to prevent divide by 0 errors
		weight := float64(i + 1)
		weights = append(weights, float64(1/weight))
	}

	_, err := f.redis.SortedSetsUnion(key, keys, weights, aggregate)

	return err
}

//----------------------------------------------------------
// Key helpers
//----------------------------------------------------------

func getDailyKey(c *models.Channel, date time.Time) string {
	if date.IsZero() {
		date = time.Now().UTC()
	}

	unix := getStartOfDay(date).Unix()

	return fmt.Sprintf("%s:%s:%s:%s:%d",
		config.MustGet().Environment, c.GroupName, PopularPostKeyName, c.Name, unix,
	)
}

func getSevenDayKey(c *models.Channel, cm *models.ChannelMessage) string {
	date := getStartOfDay(cm.CreatedAt)
	return PopularPostKey(c.GroupName, c.Name, date)
}

func PopularPostKey(group, channelName string, current time.Time) string {
	sevenDaysAgo := getXDaysAgo(current, 7)

	return fmt.Sprintf("%s:%s:%s:%s:%d-%d",
		config.MustGet().Environment, group, PopularPostKeyName, channelName,
		current.Unix(), sevenDaysAgo.Unix(),
	)
}

//----------------------------------------------------------
// helpers
//----------------------------------------------------------

func notEligibleForPopularPost(c *models.Channel, cm *models.ChannelMessage) bool {
	if c.MetaBits.Is(models.Troll) {
		return true
	}

	if c.PrivacyConstant != models.Channel_PRIVACY_PUBLIC {
		return true
	}

	if cm.MetaBits.Is(models.Troll) {
		return true
	}

	if cm.TypeConstant != models.ChannelMessage_TYPE_POST {
		return true
	}

	return false
}

//----------------------------------------------------------
// Time helpers
//----------------------------------------------------------

func createdMoreThan7DaysAgo(createdAt time.Time) bool {
	delta := time.Now().Sub(createdAt)
	return delta.Hours()/24 > 7
}

func getStartOfDay(t time.Time) time.Time {
	start := time.Duration(-t.Hour()) * time.Hour         // subtract hour
	start = start - time.Duration(t.Minute())*time.Minute // subtract minutes
	start = start - time.Duration(t.Second())*time.Second // substract seconds

	return t.Add(start)
}

func getXDaysAgo(t time.Time, days int) time.Time {
	daysAgo := -time.Hour * 24 * time.Duration(days)
	return t.Add(daysAgo)
}
