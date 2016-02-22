package models

import "fmt"

func (c *Channel) GetCacheId() int64 {
	return c.GetId()
}

func (cc *Channel) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelcontainer", id)
}

func (cc *Channel) GetForCache(id int64) (string, error) {
	return CacheForChannel(id)
}
