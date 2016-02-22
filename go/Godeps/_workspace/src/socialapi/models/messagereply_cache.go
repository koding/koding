package models

import "fmt"

func (mr *MessageReply) GetCacheId() int64 {
	return mr.MessageId
}

func (mr *MessageReply) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelmessagecontainer", id)
}

func (mr *MessageReply) GetForCache(id int64) (string, error) {
	return CacheForChannelMessage(id)
}
