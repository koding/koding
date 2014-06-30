package feeder

import (
	"errors"
	"fmt"
	"socialapi/config"
	socialmodels "socialapi/models"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"

	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/streadway/amqp"
)

type Controller struct {
	log         logging.Logger
	nameFetcher FileNameFetcher
	redisConn   *redis.RedisSession
}

var ErrIgnore = errors.New("ignore")

func (f *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	f.log.Error("an error occured deleting realtime event", err)
	delivery.Ack(false)
	return false
}

func New(log logging.Logger) *Controller {
	conf := *config.MustGet()
	conf.Redis.DB = conf.Sitemap.RedisDB
	// TODO later on seperate config structs could be better for each helper
	redisConn := helper.MustInitRedisConn(&conf)
	c := &Controller{
		log:         log,
		nameFetcher: ModNameFetcher{},
		redisConn:   redisConn,
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

func (f *Controller) queueChannelMessage(cm *socialmodels.ChannelMessage, status string) error {
	if err := validateChannelMessage(cm); err != nil {
		if err == ErrIgnore {
			return nil
		}

		return err
	}
	_, err := f.queueItem(newItemByChannelMessage(cm, status))
	if err != nil {
		return err
	}
	// when a message is added, creator's profile page must also be updated
	a := socialmodels.NewAccount()
	if err := a.ById(cm.AccountId); err != nil {
		return err
	}

	_, err = f.queueItem(newItemByAccount(a, models.STATUS_UPDATE))

	return err
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

func (f *Controller) AccountAdded(a *socialmodels.Account) error {
	_, err := f.queueItem(newItemByAccount(a, models.STATUS_UPDATE))
	return err
}

func (f *Controller) AccountUpdated(a *socialmodels.Account) error {
	_, err := f.queueItem(newItemByAccount(a, models.STATUS_UPDATE))
	return err
}

func (f *Controller) AccountDeleted(a *socialmodels.Account) error {
	_, err := f.queueItem(newItemByAccount(a, models.STATUS_DELETE))
	return err
}

func validateChannelMessage(cm *socialmodels.ChannelMessage) error {
	// TODO if it is reply update parent message
	if cm.TypeConstant != socialmodels.ChannelMessage_TYPE_POST {
		return ErrIgnore
	}

	ch := socialmodels.NewChannel()
	if err := ch.ById(cm.InitialChannelId); err != nil {
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

func newItemByAccount(a *socialmodels.Account, status string) *models.SitemapItem {
	i := &models.SitemapItem{
		Id:           a.Id,
		TypeConstant: models.TYPE_ACCOUNT,
		Status:       status,
	}

	i.Slug = a.Nick

	return i
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
	n := f.nameFetcher.Fetch(i)

	if err := f.updateFileNameCache(n); err != nil {
		return "", err
	}

	if err := f.updateFileItemCache(n, i); err != nil {
		return "", err
	}

	return n, nil
}

func (f *Controller) updateFileNameCache(fileName string) error {
	key := common.PrepareNextFileNameCacheKey()
	if _, err := f.redisConn.AddSetMembers(key, fileName); err != nil {
		return err
	}

	return nil
}

func (f *Controller) updateFileItemCache(fileName string, i *models.SitemapItem) error {
	// prepare cache key
	key := common.PrepareNextFileCacheKey(fileName)
	value := i.PrepareSetValue()
	if _, err := f.redisConn.AddSetMembers(key, value); err != nil {
		return err
	}

	return nil
}
