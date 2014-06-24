package generator

import (
	"encoding/xml"

	"socialapi/config"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"

	"github.com/jinzhu/gorm"
	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/robfig/cron"
)

type Controller struct {
	log          logging.Logger
	fileSelector FileSelector
	fileName     string
	redisConn    *redis.RedisSession
}

const (
	// before sending this interval, beware that you have to change
	// TIMERANGE in cache key file
	SCHEDULE = "0 0-59/30 * * * *"
)

var (
	cronJob *cron.Cron
)

func New(log logging.Logger) (*Controller, error) {
	conf := *config.Get()
	conf.Redis.DB = conf.Sitemap.RedisDB

	redisConn := helper.MustInitRedisConn(&conf)
	c := &Controller{
		log:          log,
		fileSelector: CachedFileSelector{},
		redisConn:    redisConn,
	}

	return c, c.initCron()
}

func (c *Controller) initCron() error {
	cronJob = cron.New()
	if err := cronJob.AddFunc(SCHEDULE, c.generate); err != nil {
		return err
	}
	cronJob.Start()

	return nil
}

func (c *Controller) Shutdown() {
	cronJob.Stop()
}

func (c *Controller) generate() {
	c.log.Info("Sitemap update started")
	for {
		name, err := c.fileSelector.Select()
		if err == redis.ErrNil {
			return
		}

		if err != nil {
			c.log.Error("Could not fetch file name: %s", err)
			return
		}
		c.log.Info("Updating sitemap: %s", name)
		// there is not any waiting sitemap updates
		if name == "" {
			return
		}

		c.fileName = name

		els, err := c.fetchElements()
		if err != nil {
			c.log.Error("Could not fetch updated elements: %s", err)
			continue
		}

		if len(els) == 0 {
			c.log.Info("Items are already added")
			continue
		}

		container := c.buildContainer(els)

		if err := c.updateFile(container); err != nil {
			c.log.Critical("Could not update file: %s", err)
			continue
		}

	}
}

func (c *Controller) fetchElements() ([]*models.SitemapItem, error) {
	key := common.PrepareCurrentFileCacheKey(c.fileName)
	els := make([]*models.SitemapItem, 0)

	for {
		item, err := c.redisConn.PopSetMember(key)
		if err != nil && err != redis.ErrNil {
			return els, err
		}

		if item == "" {
			return els, nil
		}

		i := &models.SitemapItem{}

		if err := i.Populate(item); err != nil {
			c.log.Error("Could not update item %s: %s", item, err)
			continue
		}

		els = append(els, i)
	}
}

func (c *Controller) updateFile(container *models.ItemContainer) error {
	sf := new(models.SitemapFile)
	newItem := false
	err := sf.ByName(c.fileName)
	if err == gorm.RecordNotFound {
		newItem = true
	}

	if err != nil && !newItem {
		return err
	}

	s := models.NewItemSet()
	if !newItem && len(sf.Blob) > 0 {
		if err := xml.Unmarshal(sf.Blob, &s); err != nil {
			return err
		}
	}

	s.Populate(container)
	v, err := xml.Marshal(s)
	if err != nil {
		return err
	}
	sf.Blob = v

	if newItem {
		sf.Name = c.fileName
		return sf.Create()
	}

	return sf.Update()
}

func (c *Controller) buildContainer(items []*models.SitemapItem) *models.ItemContainer {
	container := models.NewItemContainer()
	for _, v := range items {
		item := v.Definition(config.Get().Uri)
		switch v.Status {
		case models.STATUS_ADD:
			container.Add = append(container.Add, item)
		case models.STATUS_DELETE:
			container.Delete = append(container.Delete, item)
		case models.STATUS_UPDATE:
			container.Update = append(container.Update, item)
		}
	}

	return container
}
