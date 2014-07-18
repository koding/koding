package models

import (
	"fmt"

	"github.com/koding/bongo"
)

func (c *ChannelMessage) GetCacheId() int64 {
	return c.GetId()
}

func (c *ChannelMessage) CacheSet(data bongo.Cachable) (string, error) {
	return CacheForChannelMessage(data.GetCacheId())
}

func (cc *ChannelMessage) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelmessagecontainer", id)
}

func (cc *ChannelMessage) CacheGet(id int64) (string, error) {
	return CacheForChannelMessage(id)
}
