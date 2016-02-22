package models

import "fmt"

func (cp *ChannelParticipant) GetCacheId() int64 {
	return cp.ChannelId
}

func (cp *ChannelParticipant) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelcontainer", id)
}

func (cp *ChannelParticipant) GetForCache(id int64) (string, error) {
	return CacheForChannel(id)
}
