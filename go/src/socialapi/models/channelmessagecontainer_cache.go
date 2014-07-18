package models

import (
	"fmt"

	"github.com/koding/bongo"
)

func (c *ChannelMessageContainer) GetCacheId() int64 {
	if c.Message != nil {
		return c.Message.Id
	}

	return 0
}

func (c *ChannelMessageContainer) CacheSet(data bongo.Cachable) (string, error) {
	return CacheForChannelMessage(data.GetCacheId())
}

func (cc *ChannelMessageContainer) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelmessagecontainer", id)
}

func (cc *ChannelMessageContainer) CacheGet(id int64) (string, error) {
	return CacheForChannelMessage(id)
}
