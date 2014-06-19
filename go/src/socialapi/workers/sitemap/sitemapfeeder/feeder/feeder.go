package feeder

import (
	socialmodels "socialapi/models"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"

	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

type Controller struct {
	log         logging.Logger
	nameFetcher FileNameFetcher
}

func (f *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	f.log.Error("an error occured deleting realtime event", err)
	delivery.Ack(false)
	return false
}

func New(log logging.Logger) (*Controller, error) {
	c := &Controller{
		log:         log,
		nameFetcher: ModNameFetcher{},
	}

	return c, nil
}

func (f *Controller) MessageAdded(cm *socialmodels.ChannelMessage) error {
	if err := f.queueItem(newItemByChannelMessage(cm, models.STATUS_ADD)); err != nil {
		return err
	}
	// when a message is added, creator's profile page must also be updated
	a := socialmodels.NewAccount()
	if err := a.ById(cm.AccountId); err != nil {
		return err
	}

	return f.queueItem(newItemByAccount(a, models.STATUS_UPDATE))
}

func (f *Controller) MessageUpdated(cm *socialmodels.ChannelMessage) error {
	return f.queueItem(newItemByChannelMessage(cm, models.STATUS_UPDATE))
}

func (f *Controller) MessageDeleted(cm *socialmodels.ChannelMessage) error {
	return f.queueItem(newItemByChannelMessage(cm, models.STATUS_DELETE))
}

func (f *Controller) ChannelUpdated(c *socialmodels.Channel) error {
	return f.queueItem(newItemByChannel(c, models.STATUS_UPDATE))
}

func (f *Controller) ChannelAdded(c *socialmodels.Channel) error {
	return f.queueItem(newItemByChannel(c, models.STATUS_ADD))
}

func (f *Controller) ChannelDeleted(c *socialmodels.Channel) error {
	return f.queueItem(newItemByChannel(c, models.STATUS_DELETE))
}

func (f *Controller) AccountAdded(a *socialmodels.Account) error {
	return f.queueItem(newItemByAccount(a, models.STATUS_ADD))
}

func (f *Controller) AccountUpdated(a *socialmodels.Account) error {
	return f.queueItem(newItemByAccount(a, models.STATUS_UPDATE))
}

func (f *Controller) AccountDeleted(a *socialmodels.Account) error {
	return f.queueItem(newItemByAccount(a, models.STATUS_DELETE))
}

func newItemByChannelMessage(cm *socialmodels.ChannelMessage, status string) *models.SitemapItem {
	return &models.SitemapItem{
		Id:           cm.Id,
		TypeConstant: models.TYPE_CHANNEL_MESSAGE,
		Slug:         cm.Slug,
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
	return &models.SitemapItem{
		Id:           c.Id,
		TypeConstant: models.TYPE_CHANNEL,
		Slug:         c.GroupName,
		Status:       status,
	}
}

func (f *Controller) queueItem(i *models.SitemapItem) error {
	// fetch file name
	n := f.nameFetcher.Fetch(i)

	if err := f.updateFileNameCache(n); err != nil {
		return err
	}

	return f.updateFileItemCache(n, i)
}

func (f *Controller) updateFileNameCache(fileName string) error {
	key := common.PrepareFileNameCacheKey()
	redisConn := helper.MustGetRedisConn()
	if _, err := redisConn.AddSetMembers(key, fileName); err != nil {
		return err
	}

	return nil
}

func (f *Controller) updateFileItemCache(fileName string, i *models.SitemapItem) error {
	// prepare cache key
	key := common.PrepareFileCacheKey(fileName)
	redisConn := helper.MustGetRedisConn()
	value := i.PrepareSetValue()
	if _, err := redisConn.AddSetMembers(key, value); err != nil {
		return err
	}

	return nil
}
