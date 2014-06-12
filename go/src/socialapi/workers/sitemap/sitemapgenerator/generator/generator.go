package generator

import (
	"encoding/xml"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"socialapi/config"
	"socialapi/workers/helper"
	"socialapi/workers/sitemap/models"
	"time"

	"github.com/koding/logging"
	"github.com/robfig/cron"
)

type Controller struct {
	log          logging.Logger
	fileSelector FileSelector
	fileName     string
}

const (
	// TODO change this later
	// SCHEDULE = "0 0-59/15 * * * *"
	CACHEPREFIX = "sitemap"
	SCHEDULE    = "* * * * * *"
)

var (
	cronJob *cron.Cron
)

func New(log logging.Logger) (*Controller, error) {
	c := &Controller{
		log:          log,
		fileSelector: SimpleFileSelector{},
	}
	c.generate()

	return c, nil
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
	c.fileName = c.fileSelector.Select()

	els, err := c.fetchElements()
	if err != nil {
		c.log.Error("Could not fetch updated elements: %s", err)
		return
	}

	container := c.buildContainer(els)

	// TODO fetch current file and unmarshall data
	s, err := c.getCurrentSet()
	if err != nil {
		c.log.Error("Could not get current set: %s", err)
		return
	}

	if err := c.updateFile(container, s); err != nil {
		c.log.Error("Could not update file: %s", err)
	}
}

func (c *Controller) fetchElements() ([]*models.SitemapItem, error) {
	key := c.prepareCacheKey()

	redisConn := helper.MustGetRedisConn()
	members, err := redisConn.GetSetMembers(key)
	if err != nil {
		return nil, err
	}

	if len(members) == 0 {
		return nil, errors.New("members not found")
	}

	els := make([]*models.SitemapItem, len(members))
	for index, v := range members {
		i := &models.SitemapItem{}
		value, err := redisConn.String(v)
		if err != nil {
			c.log.Error("Could not get item data: %s", err)
			continue
		}

		if err := i.Populate(value); err != nil {
			c.log.Error("Could not update item %s: %s", value, err)
			continue
		}
		els[index] = i
	}

	return els, nil
}

func (c *Controller) getCurrentSet() (*models.ItemSet, error) {
	fmt.Println("dosya adi", c.fileName)
	input, err := ioutil.ReadFile(c.fileName)
	if err != nil {
		return models.NewItemSet(), nil
	}
	// defer input.Close()
	fmt.Println("hehe", input)

	fmt.Println("bura?")

	// data := make([]byte, 0)
	// in, err := input.Read(data)
	// if err != nil {
	// 	return nil, err
	// }
	// fmt.Printf("ne var %d", in)

	// if len(data) == 0 {
	// 	return nil, errors.New("empty file")
	// }

	// fmt.Println("sura?", data)
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
			item.LastModified = time.Now().UTC().Format(time.RFC3339)
			container.Update = append(container.Update, item)
		}
	}

	return container
}

func (c *Controller) updateFile(container *models.ItemContainer, set *models.ItemSet) error {
	set.Populate(container)

	// TODO no need for indent in prod
	header := []byte(xml.Header)
	res, err := xml.MarshalIndent(set, " ", "  ")
	if err != nil {
		fmt.Printf("hatali %s", err)
	}
	res = append(header, res...)

	c.write(res)

	return nil
}

func (c *Controller) write(input []byte) {
	output, err := os.Create(c.fileName)
	if err != nil {
		panic(err)
	}
	defer func() {
		if err := output.Close(); err != nil {
			panic(err)
		}
	}()
	if _, err := output.Write(input); err != nil {
		panic(err)
	}

}

func (c *Controller) prepareCacheKey() string {
	return fmt.Sprintf("%s:%s:%s",
		config.Get().Environment,
		CACHEPREFIX,
		c.fileName,
	)
}
