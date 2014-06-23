package feeder

import (
	"errors"
	socialmodels "socialapi/models"
	"socialapi/workers/sitemap/models"

	"github.com/jinzhu/gorm"
	"github.com/koding/bongo"
)

const LIMIT = 1000

var fileMap map[string]struct{}

func (c *Controller) Start() error {
	fileMap = make(map[string]struct{})
	// iterate accounts
	if err := c.createAccounts(); err != nil {
		return errors.New("account sitemap not created")
	}

	// iterate posts
	if err := c.createPosts(); err != nil {
		return errors.New("post sitemap not created")
	}

	// iterate channels
	if err := c.createChannels(); err != nil {
		return errors.New("channel sitemap not created")
	}

	c.createFileNames()

	return nil
}

func (c *Controller) createAccounts() error {
	a := socialmodels.NewAccount()

	skip := 0
	for {
		query := &bongo.Query{
			Pagination: bongo.Pagination{
				Limit: LIMIT,
				Skip:  skip,
			},
		}
		var accounts []socialmodels.Account
		err := a.Some(&accounts, query)
		if err != nil {
			return err
		}

		if len(accounts) == 0 {
			return nil
		}

		c.queueAccounts(accounts)

		skip += LIMIT
	}

	return nil
}

func (c *Controller) createPosts() error {
	cm := socialmodels.NewChannelMessage()

	skip := 0
	for {
		// fetch posts
		query := &bongo.Query{
			Pagination: bongo.Pagination{
				Limit: LIMIT,
				Skip:  skip,
			},
			Selector: map[string]interface{}{
				"type_constant": socialmodels.ChannelMessage_TYPE_POST,
			},
		}
		var posts []socialmodels.ChannelMessage
		err := cm.Some(&posts, query)
		if err != nil {
			return err
		}

		if len(posts) == 0 {
			return nil
		}

		c.queuePosts(posts)

		skip += LIMIT
	}

	return nil
}

func (c *Controller) createChannels() error {
	ch := socialmodels.NewChannel()

	skip := 0
	for {
		// fetch topics
		query := &bongo.Query{
			Pagination: bongo.Pagination{
				Limit: LIMIT,
				Skip:  skip,
			},
			Selector: map[string]interface{}{
				"type_constant": socialmodels.Channel_TYPE_TOPIC,
			},
		}
		var channels []socialmodels.Channel
		err := ch.Some(&channels, query)
		if err != nil {
			return err
		}

		if len(channels) == 0 {
			return nil
		}

		c.queueChannels(channels)

		skip += LIMIT
	}

	return nil
}

func (c *Controller) queueAccounts(accounts []socialmodels.Account) {
	for _, a := range accounts {
		si := newItemByAccount(&a, models.STATUS_ADD)
		name, err := c.queueItem(si)
		if err != nil {
			c.log.Error("Could not add account item %s: %s", a.Nick, err)
		}

		fileMap[name] = struct{}{}
	}
}

func (c *Controller) queuePosts(posts []socialmodels.ChannelMessage) {
	channelPrivacyMap := make(map[int64]string)

	for _, p := range posts {
		privacy, ok := channelPrivacyMap[p.InitialChannelId]
		if !ok {
			ch := socialmodels.NewChannel()
			err := ch.ById(p.InitialChannelId)
			if err != nil {
				c.log.Error("Could not fetch post item privacy info %d: %s", p.Id, err)
			}
			privacy = ch.PrivacyConstant
		}
		// private items must not be added to sitemap
		if privacy == socialmodels.Channel_PRIVACY_PRIVATE {
			continue
		}

		si := newItemByChannelMessage(&p, models.STATUS_ADD)
		name, err := c.queueItem(si)
		if err != nil {
			c.log.Error("Could not add post item %d: %s", p.Id, err)
		}

		fileMap[name] = struct{}{}
	}
}

func (c *Controller) queueChannels(channels []socialmodels.Channel) {
	for _, ch := range channels {
		si := newItemByChannel(&ch, models.STATUS_ADD)
		name, err := c.queueItem(si)
		if err != nil {
			c.log.Error("Could not add topic item %d: %s", ch.Id, err)
		}

		fileMap[name] = struct{}{}
	}
}

func (c *Controller) createFileNames() {
	for k := range fileMap {
		sf := new(models.SitemapFile)

		// file is already created
		err := sf.ByName(k)
		if err == nil {
			return
		}

		if err != gorm.RecordNotFound {
			c.log.Error("Could not fetch file names: %s", err)
		}

		sf.Name = k
		if err := sf.Create(); err != nil {
			c.log.Error("Could not create file names: %s", err)
		}

	}
}
