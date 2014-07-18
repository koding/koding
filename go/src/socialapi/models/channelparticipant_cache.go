package models

import (
	"fmt"

	"github.com/koding/bongo"
)

func (cp *ChannelParticipant) GetCacheId() int64 {
	return cp.ChannelId
}

func (c *ChannelParticipant) CacheSet(data bongo.Cachable) (string, error) {
	return CacheForChannel(data.GetCacheId())
}

func (cp *ChannelParticipant) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelcontainer", id)
}

func (cp *ChannelParticipant) CacheGet(id int64) (string, error) {
	return CacheForChannel(id)
}
