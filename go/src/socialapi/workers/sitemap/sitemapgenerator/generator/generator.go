package generator

import (
	"encoding/xml"
	"fmt"
	"io/ioutil"
	"os"
	"socialapi/config"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"

	"github.com/garyburd/redigo/redis"
	"github.com/koding/logging"
	"github.com/robfig/cron"
)

type Controller struct {
	log          logging.Logger
	fileSelector FileSelector
	fileName     string
}

const (
	SCHEDULE = "0 0-59/30 * * * *"
)

var (
	cronJob *cron.Cron
)

func New(log logging.Logger) (*Controller, error) {
	c := &Controller{
		log:          log,
		fileSelector: CachedFileSelector{},
	}

	return c, c.initCron()
}

func (c *Controller) initCron() error {
	cronJob := cron.New()
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
			return
		}

		container := c.buildContainer(els)

		s, err := c.getCurrentSet()
		if err != nil {
			c.log.Error("Could not get current set: %s", err)
			return
		}

		if err := c.updateFile(container, s); err != nil {
			c.log.Error("Could not update file: %s", err)
		}

		if err := new(models.SitemapFile).Upsert(name); err != nil {
			c.log.Error("Could not update file meta: %s", err)
		}

	}
}

func (c *Controller) fetchElements() ([]*models.SitemapItem, error) {
	key := common.PrepareFileCacheKey(c.fileName)
	redisConn := helper.MustGetRedisConn()
	els := make([]*models.SitemapItem, 0)

	for {
		item, err := redisConn.PopSetMember(key)
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

func (c *Controller) getCurrentSet() (*models.ItemSet, error) {
	// check if this is a new sitemap file or not
	n := fmt.Sprintf("%s.xml", c.fileName)
	if _, err := os.Stat(n); os.IsNotExist(err) {
		return models.NewItemSet(), nil
	}
	input, err := ioutil.ReadFile(n)
	if err != nil {
		return nil, err
	}

	s := models.NewItemSet()
	if err := xml.Unmarshal(input, s); err != nil {
		return nil, err
	}

	return s, nil
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

func (c *Controller) updateFile(container *models.ItemContainer, set *models.ItemSet) error {
	set.Populate(container)

	return common.XML(set, c.fileName)
}
