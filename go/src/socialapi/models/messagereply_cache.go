package models

import (
	"fmt"

	"github.com/koding/bongo"
)

func (mr *MessageReply) GetCacheId() int64 {
	return mr.MessageId
}

func (mr *MessageReply) CacheSet(data bongo.Cachable) (string, error) {
	return CacheForChannelMessage(data.GetCacheId())
}

func (mr *MessageReply) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelmessagecontainer", id)
}

func (mr *MessageReply) CacheGet(id int64) (string, error) {
	return CacheForChannelMessage(id)
}
