package models

import (
	"fmt"

	"github.com/koding/bongo"
)

var (
	channelCache map[int64]*Channel
)

func init() {
	channelCache = make(map[int64]*Channel)
}

// todo fix!!
// this will fail when a channel marked as troll
func ChannelById(id int64) (*Channel, error) {
	if channel, ok := channelCache[id]; ok {
		return channel, nil
	}

	// todo add caching here
	c := NewChannel()
	if err := c.ById(id); err != nil {
		return nil, err
	}

	return c, nil
}

func ChannelsByIds(ids []int64) ([]*Channel, error) {
	channels := make([]*Channel, len(ids))
	if len(channels) == 0 {
		return channels, nil
	}

	for i, id := range ids {
		channel, err := ChannelById(id)
		if err != nil {
			return channels, err
		}
		channels[i] = channel
	}

	return channels, nil
}

func (c *Channel) GetCacheId() int64 {
	return c.GetId()
}

func (c *Channel) CacheSet(data bongo.Cachable) (string, error) {
	return CacheForChannel(data.GetCacheId())
}

func (cc *Channel) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelcontainer", id)
}

func (cc *Channel) CacheGet(id int64) (string, error) {
	return CacheForChannel(id)
}
