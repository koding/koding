package models

import "fmt"

func (cc *ChannelContainer) GetCacheId() int64 {
	if &cc.Channel != nil {
		return cc.Channel.Id
	}

	return 0
}

func (cc *ChannelContainer) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelcontainer", id)
}

func (cc *ChannelContainer) GetForCache(id int64) (string, error) {
	return CacheForChannel(id)
}
