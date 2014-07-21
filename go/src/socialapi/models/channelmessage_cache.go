package models

import "fmt"

func (c *ChannelMessage) GetCacheId() int64 {
	return c.GetId()
}

func (cc *ChannelMessage) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelmessagecontainer", id)
}

func (cc *ChannelMessage) GetForCache(id int64) (string, error) {
	return CacheForChannelMessage(id)
}
