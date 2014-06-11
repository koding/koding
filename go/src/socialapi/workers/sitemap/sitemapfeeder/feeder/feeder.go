package feeder

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	socialmodels "socialapi/models"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/models"

	"github.com/koding/logging"
	"github.com/streadway/amqp"
)

const (
	CACHEPREFIX          = "sitemap"
	TYPE_ACCOUNT         = "account"
	TYPE_CHANNEL_MESSAGE = "channelmessage"
	TYPE_CHANNEL         = "channel"
	STATUS_ADD           = "add"
	STATUS_DELETE        = "delete"
	STATUS_UPDATE        = "update"
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
		nameFetcher: SimpleNameFetcher{},
	}

	return c, nil
}

func (f *Controller) MessageAdded(cm *socialmodels.ChannelMessage) error {
	if err := f.queueItem(newItemByChannelMessage(cm, STATUS_ADD)); err != nil {
		return err
	}
	// when a message is added, creator's profile page must also be updated
	a := socialmodels.NewAccount()
	a.Id = cm.AccountId

	return f.queueItem(newItemByAccount(a, STATUS_UPDATE))
}

func (f *Controller) MessageUpdated(cm *socialmodels.ChannelMessage) error {
	return f.queueItem(newItemByChannelMessage(cm, STATUS_UPDATE))
}

func (f *Controller) MessageDeleted(cm *socialmodels.ChannelMessage) error {
	return f.queueItem(newItemByChannelMessage(cm, STATUS_DELETE))
}

func (f *Controller) ChannelUpdated(c *socialmodels.Channel) error {
	return f.queueItem(newItemByChannel(c, STATUS_UPDATE))
}

func (f *Controller) ChannelAdded(c *socialmodels.Channel) error {
	return f.queueItem(newItemByChannel(c, STATUS_ADD))
}

func (f *Controller) ChannelDeleted(c *socialmodels.Channel) error {
	return f.queueItem(newItemByChannel(c, STATUS_DELETE))
}

func (f *Controller) AccountAdded(a *socialmodels.Account) error {
	return f.queueItem(newItemByAccount(a, STATUS_ADD))
}

func (f *Controller) AccountUpdated(a *socialmodels.Account) error {
	return f.queueItem(newItemByAccount(a, STATUS_UPDATE))
}

func (f *Controller) AccountDeleted(a *socialmodels.Account) error {
	return f.queueItem(newItemByAccount(a, STATUS_DELETE))
}

func newItemByChannelMessage(cm *socialmodels.ChannelMessage, status string) (*models.SitemapItem, error) {
	return &models.SitemapItem{
		Id:           cm.Id,
		TypeConstant: TYPE_CHANNEL_MESSAGE,
		Slug:         cm.Slug,
		Status:       status,
	}, nil
}

func newItemByAccount(a *socialmodels.Account, status string) (*models.SitemapItem, error) {
	i := &models.SitemapItem{
		Id:           a.Id,
		TypeConstant: TYPE_ACCOUNT,
		Status:       status,
	}

	oldAccount, err := modelhelper.GetAccountBySocialApiId(a.Id)
	if err != nil {
		return nil, err
	}

	i.Slug = oldAccount.Profile.Nickname

	return i, nil
}

func newItemByChannel(c *socialmodels.Channel, status string) (*models.SitemapItem, error) {
	return &models.SitemapItem{
		Id:           c.Id,
		TypeConstant: TYPE_CHANNEL,
		Slug:         c.GroupName,
		Status:       status,
	}, nil
}

func (f *Controller) queueItem(i *models.SitemapItem, err error) error {
	if err != nil {
		return err
	}

	// fetch file name
	n := f.nameFetcher.Fetch(i)
	// prepare cache key
	key := prepareFileCacheKey(n)
	redisConn := helper.MustGetRedisConn()
	value := i.PrepareSetValue()
	if _, err := redisConn.AddSetMembers(key, value); err != nil {
		return err
	}

	return nil
}

func prepareFileCacheKey(fileName string) string {
	return fmt.Sprintf("%s:%s:%s",
		config.Get().Environment,
		CACHEPREFIX,
		fileName)
}
