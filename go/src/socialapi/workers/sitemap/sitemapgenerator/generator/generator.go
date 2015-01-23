package generator

import (
	"encoding/xml"
	"fmt"
	"time"

	"socialapi/config"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/koding/redis"
	"github.com/robfig/cron"
)

type Controller struct {
	log          logging.Logger
	fileName     string
	redisConn    *redis.RedisSession
	timeInterval time.Duration
	cron         *cron.Cron
}

const (
	// before sending this interval, beware that you have to change
	// TIMERANGE in cache key file
	// run cron job every n minutes starting from 0
	SCHEDULE = "0 0-59/%d * * * *"
)

func New(log logging.Logger, redisConn *redis.RedisSession) (*Controller, error) {
	c := &Controller{
		log:          log,
		redisConn:    redisConn,
		timeInterval: common.GetInterval(),
	}

	return c, c.initCron()
}

func (c *Controller) initCron() error {
	schedule := fmt.Sprintf(SCHEDULE, int(c.timeInterval.Minutes()))
	c.cron = cron.New()
	if err := c.cron.AddFunc(schedule, c.generate); err != nil {
		return err
	}
	c.cron.Start()

	return nil
}

func (c *Controller) Shutdown() {
	c.cron.Stop()
}

func (c *Controller) generate() {
	c.log.Debug("Sitemap update started")
	for {
		name, err := c.fetchName()
		if err == redis.ErrNil {
			c.log.Debug("Sitemap update finished")
			return
		}

		if err != nil {
			c.log.Error("Could not fetch file name: %s", err)
			return
		}
		// there is not any waiting sitemap updates
		if name == "" {
			continue
		}

		c.log.Info("Updating sitemap: %s", name)

		c.fileName = name

		els, err := c.fetchElements()
		if err != nil {
			c.log.Critical("Could not fetch updated elements: %s", err)
			c.handleError(els)
			continue
		}

		if len(els) == 0 {
			c.log.Info("Items are already added")
			continue
		}

		container := c.buildContainer(els)

		if err := c.updateFile(container); err != nil {
			c.handleError(els)
			c.log.Critical("Could not update file: %s", err)
			continue
		}
	}
}

// handleError re-adds updated items to next file update queue
func (c *Controller) handleError(items []*models.SitemapItem) {
	// re-add filename to next queue
	key := common.PrepareNextFileNameSetCacheKey(int(c.timeInterval.Minutes()))
	if _, err := c.redisConn.AddSetMembers(key, c.fileName); err != nil {
		c.log.Critical("Could not re-add the filename: %s", err)
		return
	}

	key = common.PrepareNextFileCacheKey(c.fileName, int(c.timeInterval.Minutes()))
	values := make([]interface{}, len(items))
	for k := range items {
		values[k] = items[k].PrepareSetValue()
	}

	if _, err := c.redisConn.AddSetMembers(key, values...); err != nil {
		c.log.Critical("Could not re-add the updated items: %s", err)
	}

}

func (c *Controller) fetchElements() ([]*models.SitemapItem, error) {
	key := common.PrepareCurrentFileCacheKey(c.fileName, int(c.timeInterval.Minutes()))
	els := make([]*models.SitemapItem, 0)

	members, err := c.redisConn.GetSetMembers(key)
	if err != nil && err != redis.ErrNil {
		return nil, err
	}

	for i := range members {
		item, err := c.redisConn.String(members[i])
		if err != nil {
			c.log.Error("Could not convert item: %s", err)
			continue
		}
		if item == "" {
			continue
		}

		i := &models.SitemapItem{}
		// if there is a syntax error in item, do not need to try to
		// recreate it
		if err := i.Populate(item); err != nil {
			c.log.Error("Could not get item %s: %s", item, err)
			continue
		}
		els = append(els, i)
	}
	if _, err := c.redisConn.Del(key); err != nil {
		c.log.Error("Could not delete key %s: %s", key, err)
	}

	return els, nil
}

func (c *Controller) updateFile(container *models.ItemContainer) error {
	sf := models.NewSitemapFile()
	newItem := false
	err := sf.ByName(c.fileName)
	if err == bongo.RecordNotFound {
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
	hostname := config.MustGet().Hostname
	protocol := config.MustGet().Protocol
	for _, v := range items {
		item := v.Definition(protocol, hostname)
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

func (c *Controller) fetchName() (string, error) {
	item, err := c.redisConn.PopSetMember(common.PrepareCurrentFileNameSetCacheKey(int(c.timeInterval.Minutes())))
	if err != nil {
		return "", err
	}

	return item, nil
}
