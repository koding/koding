package feeder

import (
	"errors"
	"fmt"
	"math"
	socialmodels "socialapi/models"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"
	"time"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/streadway/amqp"
)

type Controller struct {
	log            logging.Logger
	redisConn      *redis.RedisSession
	updateInterval time.Duration
}

var (
	ErrIgnore      = errors.New("ignore")
	ErrInvalidType = errors.New("invalid type")
)

const (
	DefaultInterval   = 30 * time.Minute
	MaxItemSizeInFile = 1000
)

func (f *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	f.log.Error("an error occurred deleting realtime event", err)
	delivery.Ack(false)
	return false
}

func New(log logging.Logger, redisConn *redis.RedisSession) *Controller {
	c := &Controller{
		log:            log,
		redisConn:      redisConn,
		updateInterval: common.GetInterval(),
	}

	return c
}

func (f *Controller) MessageAdded(cm *socialmodels.ChannelMessage) error {
	return f.queueChannelMessage(cm, models.STATUS_UPDATE)
}

func (f *Controller) MessageUpdated(cm *socialmodels.ChannelMessage) error {
	return f.queueChannelMessage(cm, models.STATUS_UPDATE)
}

func (f *Controller) MessageDeleted(cm *socialmodels.ChannelMessage) error {
	return f.queueChannelMessage(cm, models.STATUS_DELETE)
}

// queueChannelMessage updates account sitemap file if message's initial channel is public.
// Also adds post's url to the sitemap
func (f *Controller) queueChannelMessage(cm *socialmodels.ChannelMessage, status string) error {
	if err := validateChannelMessage(cm); err != nil {
		if err == ErrIgnore {
			return nil
		}

		return err
	}

	// add post's url to the sitemap
	_, err := f.queueItem(newItemByChannelMessage(cm, status))
	if err != nil {
		return err
	}

	return nil
}

func (f *Controller) ChannelMessageListUpdated(c *socialmodels.ChannelMessageList) error {
	return f.queueChannelMessageList(c, models.STATUS_UPDATE)
}

func (f *Controller) ChannelMessageListAdded(c *socialmodels.ChannelMessageList) error {
	return f.queueChannelMessageList(c, models.STATUS_UPDATE)
}

func (f *Controller) ChannelMessageListDeleted(c *socialmodels.ChannelMessageList) error {
	return f.queueChannelMessageList(c, models.STATUS_DELETE)
}

func (f *Controller) queueChannelMessageList(c *socialmodels.ChannelMessageList, status string) error {
	ch, err := socialmodels.ChannelById(c.ChannelId)
	if err != nil {
		return nil
	}

	// Even validateChannel returns just ErrIgnore now, for preventing
	// potential future errors, we are checking for err existence here
	if err := validateChannel(ch); err != nil {
		if err == ErrIgnore {
			return nil
		}

		return err
	}

	_, err = f.queueItem(newItemByChannel(ch, status))

	return err
}

func validateChannelMessage(cm *socialmodels.ChannelMessage) error {
	// TODO if it is reply update parent message
	if cm.TypeConstant != socialmodels.ChannelMessage_TYPE_POST {
		return ErrIgnore
	}

	ch, err := socialmodels.ChannelById(cm.InitialChannelId)
	if err != nil {
		return err
	}

	// it could be a message in a private group
	if ch.PrivacyConstant == socialmodels.Channel_PRIVACY_PRIVATE {
		return ErrIgnore
	}

	return nil
}

func validateChannel(c *socialmodels.Channel) error {
	// for now we are only adding topics, but later on we could add groups here
	if c.TypeConstant != socialmodels.Channel_TYPE_TOPIC &&
		c.TypeConstant != socialmodels.Channel_TYPE_GROUP {
		return ErrIgnore
	}

	if c.PrivacyConstant == socialmodels.Channel_PRIVACY_PRIVATE {
		return ErrIgnore
	}

	return nil
}

func newItemByChannelMessage(cm *socialmodels.ChannelMessage, status string) *models.SitemapItem {
	return &models.SitemapItem{
		Id:           cm.Id,
		TypeConstant: models.TYPE_CHANNEL_MESSAGE,
		Slug:         fmt.Sprintf("%s/%s", "Post", cm.Slug),
		Status:       status,
	}
}

func newItemByChannel(c *socialmodels.Channel, status string) *models.SitemapItem {
	slug := "Public"
	switch c.TypeConstant {
	case socialmodels.Channel_TYPE_TOPIC:
		slug = fmt.Sprintf("Topic/%s", c.Name)
	case socialmodels.Channel_TYPE_GROUP:
		// TODO implement when group routes are defined
	}

	return &models.SitemapItem{
		Id:           c.Id,
		TypeConstant: models.TYPE_CHANNEL,
		Slug:         slug,
		Status:       status,
	}
}

// queueItem push an item to cache and returns related file name
func (f *Controller) queueItem(i *models.SitemapItem) (string, error) {
	// fetch file name
	n := f.fetchFileName(i)

	if err := f.updateFileNameCache(n); err != nil {
		return "", err
	}

	if err := f.updateFileItemCache(n, i); err != nil {
		return "", err
	}

	return n, nil
}

func (f *Controller) updateFileNameCache(fileName string) error {
	key := common.PrepareNextFileNameSetCacheKey(int(f.updateInterval.Minutes()))
	if _, err := f.redisConn.AddSetMembers(key, fileName); err != nil {
		return err
	}

	return nil
}

func (f *Controller) updateFileItemCache(fileName string, i *models.SitemapItem) error {
	// prepare cache key
	key := common.PrepareNextFileCacheKey(fileName, int(f.updateInterval.Minutes()))
	value := i.PrepareSetValue()
	if _, err := f.redisConn.AddSetMembers(key, value); err != nil {
		return err
	}

	return nil
}

func (f *Controller) fetchFileName(i *models.SitemapItem) string {
	switch i.TypeConstant {
	case models.TYPE_CHANNEL_MESSAGE:
		return fetchChannelMessageName(i.Id)
	case models.TYPE_CHANNEL:
		return fetchChannelName(i.Id)
	default:
		panic(ErrInvalidType)
	}
}

func fetchChannelMessageName(id int64) string {
	remainder := math.Mod(float64(id), float64(MaxItemSizeInFile))
	return fmt.Sprintf("channel_message_%d", int64(remainder))
}

func fetchChannelName(id int64) string {
	remainder := math.Mod(float64(id), float64(MaxItemSizeInFile))
	return fmt.Sprintf("channel_%d", int64(remainder))
}
