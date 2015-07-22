package webhook

import (
	"fmt"
	"socialapi/models"
	"strconv"
	"time"

	"github.com/koding/cache"
)

const cacheSize = 10000

var Cache *StaticCache

func init() {
	// later on instead of time based invalidation,
	// we need to invalidate cache with update messages
	ciCache := cache.NewMemoryWithTTL(10 * time.Second)
	ciCache.StartGC(1 * time.Second)

	Cache = &StaticCache{
		Integration: &IntegrationCache{
			name: cache.NewLRU(cacheSize),
			id:   cache.NewLRU(cacheSize),
		},
		ChannelIntegration: &ChannelIntegrationCache{
			token: ciCache,
		},
		BotChannel: &BotChannelCache{
			group: cache.NewLRU(cacheSize),
		},
	}
}

type StaticCache struct {
	Integration        *IntegrationCache
	ChannelIntegration *ChannelIntegrationCache
	BotChannel         *BotChannelCache
}

type IntegrationCache struct {
	name cache.Cache
	id   cache.Cache
}

func (i *IntegrationCache) ByName(name string) (*Integration, error) {
	data, err := i.name.Get(name)
	if err == nil {
		in, ok := data.(*Integration)
		if ok {
			return in, nil
		}
	}

	if err != cache.ErrNotFound {
		return nil, err
	}

	in := NewIntegration()
	if err := in.ByName(name); err != nil {
		return nil, err
	}

	if err := i.SetToCache(in); err != nil {
		return nil, err
	}

	return in, nil
}

func (i *IntegrationCache) ById(id int64) (*Integration, error) {
	data, err := i.id.Get(strconv.FormatInt(id, 10))
	if err == nil {
		in, ok := data.(*Integration)
		if ok {
			return in, nil
		}
	}

	if err != cache.ErrNotFound {
		return nil, err
	}

	in := NewIntegration()
	if err := in.ById(id); err != nil {
		return nil, err
	}

	if err := i.SetToCache(in); err != nil {
		return nil, err
	}

	return in, nil
}

func (i *IntegrationCache) SetToCache(in *Integration) error {
	if err := i.name.Set(in.Name, in); err != nil {
		return err
	}

	return i.id.Set(strconv.FormatInt(in.Id, 10), in)
}

//////////// ChannelIntegrationCache ///////////////
type ChannelIntegrationCache struct {
	token cache.Cache
}

func (i *ChannelIntegrationCache) ByToken(token string) (*ChannelIntegration, error) {
	data, err := i.token.Get(token)
	if err == nil {
		in, ok := data.(*ChannelIntegration)
		if ok {
			return in, nil
		}
	}

	if err != cache.ErrNotFound {
		return nil, err
	}

	in := NewChannelIntegration()
	if err := in.ByToken(token); err != nil {
		return nil, err
	}

	if err := i.SetToCache(in); err != nil {
		return nil, err
	}

	return in, nil
}

func (i *ChannelIntegrationCache) SetToCache(ci *ChannelIntegration) error {
	return i.token.Set(ci.Token, ci)
}

///////////// BotChannelCache ////////////////
type BotChannelCache struct {
	group cache.Cache
}

func (b *BotChannelCache) ByAccountAndGroup(a *models.Account, groupName string) (*models.Channel, error) {
	key := b.generateKey(a, groupName)
	data, err := b.group.Get(key)
	if err == nil {
		bc, ok := data.(*models.Channel)
		if ok {
			return bc, nil
		}
	}

	if err != cache.ErrNotFound {
		return nil, err
	}

	c, err := fetchBotChannel(a, groupName)
	if err != nil {
		return nil, err
	}

	if err := b.SetToCache(a, groupName, c); err != nil {
		return nil, err
	}

	return c, nil

}

func (b *BotChannelCache) SetToCache(a *models.Account, groupName string, c *models.Channel) error {
	key := b.generateKey(a, groupName)

	return b.group.Set(key, c)
}

func (b *BotChannelCache) generateKey(a *models.Account, groupName string) string {
	return fmt.Sprintf("%d-%s", a.Id, groupName)
}
