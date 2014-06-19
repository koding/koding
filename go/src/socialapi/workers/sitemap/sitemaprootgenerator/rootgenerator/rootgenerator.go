package rootgenerator

import (
	"socialapi/config"
	"socialapi/workers/sitemap/common"
	"socialapi/workers/sitemap/models"

	"github.com/koding/bongo"
	"github.com/koding/logging"
	"github.com/robfig/cron"
)

type Controller struct {
	log logging.Logger
}

const (
	SCHEDULE = "0 5-59/30 * * * *"
)

var cronJob *cron.Cron

func New(log logging.Logger) (*Controller, error) {
	c := &Controller{
		log: log,
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

func (c *Controller) generate() {
	c.log.Info("Sitemap root update started")
	sf := new(models.SitemapFile)

	files := make([]models.SitemapFile, 0)
	query := &bongo.Query{}

	if err := sf.Some(&files, query); err != nil {
		c.log.Error("An error occurred: %s", err)
		return
	}

	set := models.NewSitemapSet(files, config.Get().Uri)

	common.XML(set, "sitemap")
}

func (c *Controller) Shutdown() {
	cronJob.Stop()
}
