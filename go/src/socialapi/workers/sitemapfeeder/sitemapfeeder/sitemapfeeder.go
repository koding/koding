package sitemapfeeder

import (
	"fmt"
	"koding/db/mongodb/modelhelper"
	"socialapi/config"
	"socialapi/models"
	"socialapi/workers/helper"

	"github.com/koding/logging"
	"github.com/koding/rabbitmq"
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
	rmqConn     *amqp.Connection
	nameFetcher FileNameFetcher
}

type SitemapItem struct {
	Id           int64
	TypeConstant string
	Slug         string
	Status       string
}

func (f *Controller) DefaultErrHandler(delivery amqp.Delivery, err error) bool {
	f.log.Error("an error occured deleting realtime event", err)
	delivery.Ack(false)
	return false
}

func New(rmq *rabbitmq.RabbitMQ, log logging.Logger) (*Controller, error) {
	rmqConn, err := rmq.Connect("NewSitemapFeederWorkerController")
	if err != nil {
		return nil, err
	}

	c := &Controller{
		log:         log,
		rmqConn:     rmqConn.Conn(),
		nameFetcher: SimpleNameFetcher{},
	}

	return c, nil
}

func (f *Controller) MessageAdded(cm *models.ChannelMessage) error {
	if err := f.queueItem(newItemByChannelMessage(cm, STATUS_ADD)); err != nil {
		return err
	}
	// when a message is added, creator's profile page must also be updated
	a := models.NewAccount()
	a.Id = cm.AccountId

	return f.queueItem(newItemByAccount(a, STATUS_UPDATE))
}

func (f *Controller) MessageUpdated(cm *models.ChannelMessage) error {
	return f.queueItem(newItemByChannelMessage(cm, STATUS_UPDATE))
}

func (f *Controller) MessageDeleted(cm *models.ChannelMessage) error {
	return f.queueItem(newItemByChannelMessage(cm, STATUS_DELETE))
}

func (f *Controller) ChannelUpdated(c *models.Channel) error {
	return f.queueItem(newItemByChannel(c, STATUS_UPDATE))
}

func (f *Controller) ChannelAdded(c *models.Channel) error {
	return f.queueItem(newItemByChannel(c, STATUS_ADD))
}

func (f *Controller) ChannelDeleted(c *models.Channel) error {
	return f.queueItem(newItemByChannel(c, STATUS_DELETE))
}

func (f *Controller) AccountAdded(a *models.Account) error {
	return f.queueItem(newItemByAccount(a, STATUS_ADD))
}

func (f *Controller) AccountUpdated(a *models.Account) error {
	return f.queueItem(newItemByAccount(a, STATUS_UPDATE))
}

func (f *Controller) AccountDeleted(a *models.Account) error {
	return f.queueItem(newItemByAccount(a, STATUS_DELETE))
}

func newItemByChannelMessage(cm *models.ChannelMessage, status string) (*SitemapItem, error) {
	return &SitemapItem{
		Id:           cm.Id,
		TypeConstant: TYPE_CHANNEL_MESSAGE,
		Slug:         cm.Slug,
		Status:       status,
	}, nil
}

func newItemByAccount(a *models.Account, status string) (*SitemapItem, error) {
	i := &SitemapItem{
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

func newItemByChannel(c *models.Channel, status string) (*SitemapItem, error) {
	return &SitemapItem{
		Id:           c.Id,
		TypeConstant: TYPE_CHANNEL,
		Slug:         c.GroupName,
		Status:       status,
	}, nil
}

func (f *Controller) queueItem(i *SitemapItem, err error) error {
	if err != nil {
		return err
	}

	// fetch file name
	n := f.nameFetcher.Fetch(i)
	// prepare cache key
	key := prepareFileCacheKey(n)
	redisConn := helper.MustGetRedisConn()
	value := i.prepareSetValue()
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

func (s *SitemapItem) prepareSetValue() string {
	return fmt.Sprintf("%d:%s:%s:%s", s.Id, s.TypeConstant, s.Slug, s.Status)
}
