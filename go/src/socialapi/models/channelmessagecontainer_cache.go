package models

import "fmt"

func (c *ChannelMessageContainer) GetCacheId() int64 {
	if c.Message != nil {
		return c.Message.Id
	}

	return 0
}

func (cc *ChannelMessageContainer) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelmessagecontainer", id)
}

func (cc *ChannelMessageContainer) GetForCache(id int64) (string, error) {
	return CacheForChannelMessage(id)
}
