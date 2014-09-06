package popularpost

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"time"

	"github.com/jinzhu/now"
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

	keyname := &KeyName{
		GroupName: c.GroupName, ChannelName: c.Name,
		Time: cm.CreatedAt,
	}

	err = f.saveToDailyBucket(keyname, incrementCount, i.MessageId)
	if err != nil {
		return err
	}

	err = f.saveToSevenDayBucket(keyname, incrementCount, i.MessageId)
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) saveToDailyBucket(k *KeyName, inc int, id int64) error {
	_, err := f.redis.SortedSetIncrBy(k.Today(), inc, id)
	return err
}

func (f *Controller) saveToSevenDayBucket(k *KeyName, inc int, id int64) error {
	key := k.Weekly()

	exists := f.redis.Exists(key)
	if exists {
		_, err := f.redis.SortedSetIncrBy(key, inc, id)
		return err
	}

	err := f.createSevenDayCombinedBucket(k)
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) createSevenDayCombinedBucket(k *KeyName) error {
	keys, weights := []interface{}{}, []interface{}{}

	from := getStartOfDay(k.Time)
	aggregate := "SUM"

	for i := 0; i <= 6; i++ {
		currentDate := getXDaysAgo(from, i)
		keys = append(keys, k.Before(currentDate))

		// add by 1 to prevent divide by 0 errors
		weight := float64(i + 1)
		weights = append(weights, float64(1/weight))
	}

	_, err := f.redis.SortedSetsUnion(k.Weekly(), keys, weights, aggregate)

	return err
}

func PopularPostKey(groupName, channelName string, current time.Time) string {
	name := KeyName{
		GroupName: groupName, ChannelName: channelName,
		Time: current.UTC(),
	}

	return name.Weekly()
}

//----------------------------------------------------------
// KeyName
//----------------------------------------------------------

type KeyName struct {
	GroupName, ChannelName string
	Time                   time.Time
}

func (k *KeyName) Today() string {
	return k.do(getStartOfDay(k.Time))
}

func (k *KeyName) Before(t time.Time) string {
	return k.do(t)
}

func (k *KeyName) Weekly() string {
	current := getStartOfDay(k.Time.UTC())
	sevenDaysAgo := getXDaysAgo(current, 7).UTC().Unix()

	return fmt.Sprintf("%s-%d", k.do(current), sevenDaysAgo)
}

func (k *KeyName) do(t time.Time) string {
	return fmt.Sprintf("%s:%s:%s:%s:%d",
		config.MustGet().Environment, k.GroupName, PopularPostKeyName,
		k.ChannelName, t.UTC().Unix(),
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

//----------------------------------------------------------
func (t *Controller) CreateKeyAtStartOfDay(groupName, channelName string) {
	endOfDay := now.EndOfDay().UTC()
	difference := time.Now().UTC().Sub(endOfDay)

	<-time.After(difference)

	keyname := &KeyName{
		GroupName: groupName, ChannelName: channelName,
		Time: time.Now().UTC(),
	}

	t.createSevenDayCombinedBucket(keyname)
}
