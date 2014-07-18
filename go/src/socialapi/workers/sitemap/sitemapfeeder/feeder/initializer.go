package feeder

import (
	"fmt"
	socialmodels "socialapi/models"
	"socialapi/workers/sitemap/models"

	"github.com/koding/bongo"
)

const LIMIT = 1000

var fileMap map[string]struct{}

func (c *Controller) Start() error {
	fileMap = make(map[string]struct{})
	// iterate accounts
	if err := c.createAccounts(); err != nil {
		return fmt.Errorf("account sitemap not created: %s", err)
	}

	// iterate posts
	if err := c.createPosts(); err != nil {
		return fmt.Errorf("post sitemap not created: %s", err)
	}

	// iterate channels
	if err := c.createChannels(); err != nil {
		return fmt.Errorf("channel sitemap not created: %s", err)
	}

	return c.createFileNames()
}

func (c *Controller) createAccounts() error {
	a := socialmodels.NewAccount()

	query := &bongo.Query{
		Pagination: bongo.Pagination{
			Limit: LIMIT,
			Skip:  0,
		},
	}
	for {
		var accounts []socialmodels.Account
		err := a.Some(&accounts, query)
		if err != nil {
			return err
		}

		if len(accounts) == 0 {
			return nil
		}

		c.queueAccounts(accounts)

		query.Pagination.Skip += LIMIT
	}

	return nil
}

func (c *Controller) createPosts() error {
	cm := socialmodels.NewChannelMessage()

	query := &bongo.Query{
		Pagination: bongo.Pagination{
			Limit: LIMIT,
			Skip:  0,
		},
		Selector: map[string]interface{}{
			"type_constant": socialmodels.ChannelMessage_TYPE_POST,
		},
	}
	for {
		// fetch posts
		var posts []socialmodels.ChannelMessage
		err := cm.Some(&posts, query)
		if err != nil {
			return err
		}

		if len(posts) == 0 {
			return nil
		}

		c.queuePosts(posts)

		query.Pagination.Skip += LIMIT
	}

	return nil
}

func (c *Controller) createChannels() error {
	ch := socialmodels.NewChannel()

	query := &bongo.Query{
		Pagination: bongo.Pagination{
			Limit: LIMIT,
			Skip:  0,
		},
		Selector: map[string]interface{}{
			"type_constant": socialmodels.Channel_TYPE_TOPIC,
		},
	}
	for {
		// fetch topics
		var channels []socialmodels.Channel
		err := ch.Some(&channels, query)
		if err != nil {
			return err
		}

		if len(channels) == 0 {
			return nil
		}

		c.queueChannels(channels)

		query.Pagination.Skip += LIMIT
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
				continue
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

func (c *Controller) createFileNames() error {
	for k := range fileMap {
		sf := models.NewSitemapFile()

		// file is already created
		err := sf.ByName(k)
		if err == nil {
			return err
		}

		if err != bongo.RecordNotFound {
			c.log.Error("Could not fetch file names: %s", err)
			return err
		}

		sf.Name = k
		if err := sf.Create(); err != nil {
			c.log.Error("Could not create file names: %s", err)
			return err
		}
	}

	return nil
}
