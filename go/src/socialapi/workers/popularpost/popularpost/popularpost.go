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
	keyExistsRegistry  = map[string]bool{}
)

func init() {
	now.FirstDayMonday = true
}

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

	if !isEligibleForPopularPost(c, cm) {
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

	weight := getWeight(i.CreatedAt, cm.CreatedAt, incrementCount)

	keyname = &KeyName{
		GroupName: c.GroupName, ChannelName: c.Name,
		Time: time.Now().UTC(),
	}

	err = f.saveToSevenDayBucket(keyname, weight, i.MessageId)
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) saveToDailyBucket(k *KeyName, inc int, id int64) error {
	key := k.Today()

	score, err := f.redis.SortedSetIncrBy(key, inc, id)
	if err != nil {
		return err
	}

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

	_, ok := keyExistsRegistry[key]
	if !ok {
		exists := f.redis.Exists(key)
		if !exists {
			err := f.CreateSevenDayBucket(k)
			if err != nil {
				return err
			}
		}

		keyExistsRegistry[key] = true

		return nil
	}

	score, err := f.redis.SortedSetIncrBy(key, inc, id)
	if err != nil {
		return err
	}

	if score <= 0 {
		_, err := f.redis.SortedSetRem(key, id)
		if err != nil {
			return err
		}
	}

	return nil
}

func (f *Controller) CreateSevenDayBucket(k *KeyName) error {
	keys, weights := []string{}, []interface{}{}

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
	return k.String(getStartOfDay(k.Time))
}

func (k *KeyName) Before(t time.Time) string {
	return k.String(t)
}

func (k *KeyName) Weekly() string {
	current := getStartOfDay(k.Time.UTC())
	sevenDaysAgo := getDaysAgo(current, 7).UTC().Unix()

	return fmt.Sprintf("%s-%d", k.String(current), sevenDaysAgo)
}

func (k *KeyName) String(t time.Time) string {
	return fmt.Sprintf("%s:%s:%s:%s:%d",
		config.MustGet().Environment, k.GroupName, PopularPostKeyName,
		k.ChannelName, t.UTC().Unix(),
	)
}

//----------------------------------------------------------
// helpers
//----------------------------------------------------------

func isEligibleForPopularPost(c *models.Channel, cm *models.ChannelMessage) bool {
	if c.MetaBits.Is(models.Troll) {
		return false
	}

	if c.PrivacyConstant != models.Channel_PRIVACY_PUBLIC {
		return false
	}

	if cm.MetaBits.Is(models.Troll) {
		return false
	}

	if cm.TypeConstant != models.ChannelMessage_TYPE_POST {
		return false
	}

	if isCreatedMoreThan7DaysAgo(cm.CreatedAt) {
		return false
	}

	return true
}

//----------------------------------------------------------
// Time helpers
//----------------------------------------------------------

func isCreatedMoreThan7DaysAgo(t time.Time) bool {
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

	t.CreateSevenDayBucket(keyname)
}

func (t *Controller) ResetRegistry() {
	keyExistsRegistry = map[string]bool{}
}

func getWeight(iCreatedAt, mCreatedAt time.Time, inc int) string {
	difference := int(iCreatedAt.Sub(mCreatedAt).Hours()/24) + 1
	weight := 1 / float64(difference) * float64(inc)

	return fmt.Sprintf("%.1f", weight)
}
