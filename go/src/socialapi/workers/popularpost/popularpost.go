package popularpost

import (
	"fmt"
	"socialapi/config"
	"socialapi/models"
	"sync"
	"time"

	"github.com/jinzhu/now"
	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/streadway/amqp"
)

var (
	PopularPostKeyName = "popularpost"
)

func init() {
	now.FirstDayMonday = true
}

type Controller struct {
	log   logging.Logger
	redis *redis.RedisSession

	regMux            sync.Mutex
	keyExistsRegistry map[string]bool
}

func (t *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	if delivery.Redelivered {
		t.log.Error("Redelivered message gave error again, putting to maintenance queue", err)
		delivery.Ack(false)
		return true
	}

	t.log.Error("an error occurred putting message back to queue", err)
	delivery.Nack(false, true)
	return false
}

func New(log logging.Logger, redis *redis.RedisSession) *Controller {
	return &Controller{
		log:               log,
		redis:             redis,
		keyExistsRegistry: make(map[string]bool),
	}
}

func (f *Controller) InteractionSaved(i *models.Interaction) error {
	return f.handleInteraction(1, i)
}

func (f *Controller) InteractionDeleted(i *models.Interaction) error {
	return f.handleInteraction(-1, i)
}

func (f *Controller) handleInteraction(inc float64, i *models.Interaction) error {
	cm, err := models.Cache.Message.ById(i.MessageId)
	if err != nil {
		return err
	}

	c, err := models.Cache.Channel.ById(cm.InitialChannelId)
	if err != nil {
		return err
	}

	if !isEligibleForPopularPost(c, cm) {
		f.log.Debug(fmt.Sprintf("Not eligible Interaction Id:%d", i.Id))
		return nil
	}

	keyname := &KeyName{
		GroupName: c.GroupName, ChannelName: c.Name,
		Time: cm.CreatedAt,
	}

	err = f.saveToBucket(keyname.Today(), inc, i.MessageId)
	if err != nil {
		return err
	}

	keyname = &KeyName{
		GroupName: c.GroupName, ChannelName: c.Name,
		Time: time.Now().UTC(),
	}
	weight := getWeight(i.CreatedAt, cm.CreatedAt, inc)

	err = f.saveToSevenDayBucket(keyname, weight, i.MessageId)
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) saveToBucket(key string, inc float64, id int64) error {
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

func (f *Controller) saveToSevenDayBucket(k *KeyName, inc float64, id int64) error {
	f.regMux.Lock()
	defer f.regMux.Unlock()

	key := k.Weekly()

	_, ok := f.keyExistsRegistry[key]
	if !ok {
		exists := f.redis.Exists(key)
		if !exists {
			err := f.CreateSevenDayBucket(k)
			if err != nil {
				return err
			}
		}

		f.keyExistsRegistry[key] = true
	}

	err := f.saveToBucket(key, inc, id)
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) CreateSevenDayBucket(k *KeyName) error {
	keys, weights := []string{}, []interface{}{}

	from := getStartOfDayUTC(k.Time)
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

func (f *Controller) CreateWeeklyBuckets() error {
	query := &bongo.Query{
		Selector: map[string]interface{}{
			"type_constant": models.Channel_TYPE_GROUP,
		},
	}

	var channels []models.Channel
	if err := models.NewChannel().Some(&channels, query); err != nil {
		return err
	}

	now := time.Now().UTC()
	for _, channel := range channels {
		keyname := &KeyName{
			GroupName:   channel.GroupName,
			ChannelName: channel.Name,
			Time:        now,
		}

		if err := f.CreateSevenDayBucket(keyname); err != nil {
			return err
		}
	}

	f.ResetRegistry()

	return nil
}

func (f *Controller) ResetRegistry() {
	f.regMux.Lock()
	f.keyExistsRegistry = map[string]bool{}
	f.regMux.Unlock()
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
	GroupName   string
	ChannelName string
	Time        time.Time
}

func (k *KeyName) Today() string {
	return k.String(getStartOfDayUTC(k.Time))
}

func (k *KeyName) Before(t time.Time) string {
	return k.String(t)
}

func (k *KeyName) Weekly() string {
	current := getStartOfDayUTC(k.Time.UTC())
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

	// we need popular posts to work with private teams ~ CS
	//
	// if c.PrivacyConstant != models.Channel_PRIVACY_PUBLIC {
	// 	return false
	// }

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

func getStartOfDayUTC(t time.Time) time.Time {
	t = t.UTC()
	return now.New(t).BeginningOfDay()
}

func getDaysAgo(t time.Time, days int) time.Time {
	t = t.UTC()
	daysAgo := -time.Hour * 24 * time.Duration(days)

	return t.Add(daysAgo)
}

func getWeight(iCreatedAt, mCreatedAt time.Time, inc float64) float64 {
	difference := int(iCreatedAt.Sub(mCreatedAt).Hours()/24) + 1
	weight := 1 / float64(difference) * float64(inc)
	truncated := float64(int(weight*10)) / 10

	return truncated
}
