package models

import (
	"fmt"

	"github.com/koding/bongo"
)

func (i *Interaction) GetCacheId() int64 {
	return i.MessageId
}

func (i *Interaction) CacheSet(data bongo.Cachable) (string, error) {
	return CacheForChannelMessage(data.GetCacheId())
}

func (cc *Interaction) CachePrefix(id int64) string {
	return fmt.Sprintf("%s:%d", "channelmessagecontainer", id)
}

func (cc *Interaction) CacheGet(id int64) (string, error) {
	return CacheForChannelMessage(id)
}
