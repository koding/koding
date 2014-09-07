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
	KeyExistsRegistry  = map[string]bool{}
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

	keyname := &KeyName{
		GroupName: c.GroupName, ChannelName: c.Name,
		Time: cm.CreatedAt,
	}

	err = f.saveToDailyBucket(keyname, incrementCount, i.MessageId)
	if err != nil {
		return err
	}

	difference := int(i.CreatedAt.Sub(cm.CreatedAt).Hours()/24) + 1
	weight := 1 / float64(difference) * float64(incrementCount)
	rounded := fmt.Sprintf("%.1f", weight)

	keyname = &KeyName{
		GroupName: c.GroupName, ChannelName: c.Name,
		Time: time.Now().UTC(),
	}

	err = f.saveToSevenDayBucket(keyname, rounded, i.MessageId)
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) saveToDailyBucket(k *KeyName, inc int, id int64) error {
	key := k.Today()

	_, err := f.redis.SortedSetIncrBy(key, inc, id)
	if err != nil {
		return err
	}

	score, err := f.redis.SortedSetScore(key, id)
	if score <= 0 {
		_, err := f.redis.SortedSetRem(key, id)
		if err != nil {
			return err
		}
	}

	return err
}

func (f *Controller) saveToSevenDayBucket(k *KeyName, inc string, id int64) error {
	key := k.Weekly()

	_, ok := KeyExistsRegistry[key]
	if !ok {
		exists := f.redis.Exists(key)
		if !exists {
			err := f.createSevenDayBucket(k)
			if err != nil {
				return err
			}
		}

		KeyExistsRegistry[key] = true

		return nil
	}

	_, err := f.redis.SortedSetIncrBy(key, inc, id)
	if err != nil {
		return err
	}

	score, err := f.redis.SortedSetScore(key, id)
	if score <= 0 {
		_, err := f.redis.SortedSetRem(key, id)
		if err != nil {
			return err
		}
	}

	return nil
}

func (f *Controller) createSevenDayBucket(k *KeyName) error {
	keys, weights := []interface{}{}, []interface{}{}

	from := getStartOfDay(k.Time)
	aggregate := "SUM"

	for i := 0; i <= 6; i++ {
		currentDate := getDaysAgo(from, i)
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
	sevenDaysAgo := getDaysAgo(current, 7).UTC().Unix()

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

	if createdMoreThan7DaysAgo(cm.CreatedAt) {
		return true
	}

	return false
}

//----------------------------------------------------------
// Time helpers
//----------------------------------------------------------

func createdMoreThan7DaysAgo(t time.Time) bool {
	t = t.UTC()
	delta := time.Now().Sub(t)

	return delta.Hours()/24 > 7
}

func getStartOfDay(t time.Time) time.Time {
	t = t.UTC()
	return now.New(t).BeginningOfDay()
}

func getDaysAgo(t time.Time, days int) time.Time {
	t = t.UTC()
	daysAgo := -time.Hour * 24 * time.Duration(days)

	return t.Add(daysAgo)
}

//----------------------------------------------------------
func (t *Controller) CreateKeyAtStartOfDay(groupName, channelName string) {
	endOfDay := now.EndOfDay().UTC()
	difference := time.Now().UTC().Sub(endOfDay)

	<-time.After(difference * -1)

	keyname := &KeyName{
		GroupName: groupName, ChannelName: channelName,
		Time: time.Now().UTC(),
	}

	t.createSevenDayBucket(keyname)
}

func (t *Controller) ResetRegistry() {
	KeyExistsRegistry = map[string]bool{}
}
