package models

import "fmt"

func (i *Interaction) GetCacheId() int64 {
	return i.MessageId
}
func (cc *Interaction) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelmessagecontainer", id)
}

func (cc *Interaction) GetForCache(id int64) (string, error) {
	return CacheForChannelMessage(id)
}
