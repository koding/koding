package models

import (
	"fmt"

	"github.com/koding/bongo"
)

func (cc *ChannelContainer) GetCacheId() int64 {
	if &cc.Channel != nil {
		return cc.Channel.Id
	}

	return 0
}

func (c *ChannelContainer) CacheSet(data bongo.Cachable) (string, error) {
	return CacheForChannel(data.GetCacheId())
}

func (cc *ChannelContainer) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelcontainer", id)
}

func (cc *ChannelContainer) CacheGet(id int64) (string, error) {
	return CacheForChannel(id)
}
