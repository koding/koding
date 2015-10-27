package models

import (
	"fmt"

	"github.com/koding/cache"
)

var Cache *StaticCache

var cacheSize = 10000

func init() {
	Cache = &StaticCache{
		NotificationContent: &NotificationContentCache{
			typeConstantTargetId: cache.NewLRU(cacheSize),
		},
	}
}

type StaticCache struct {
	NotificationContent *NotificationContentCache
}

type NotificationContentCache struct {
	typeConstantTargetId cache.Cache
}

func (a *NotificationContentCache) ByTypeConstantAndTargetID(typeConstant string, targetId int64) (*NotificationContent, error) {
	ck := cacheKey(typeConstant, targetId)

	data, err := a.typeConstantTargetId.Get(ck)
	if err != nil && err != cache.ErrNotFound {
		return nil, err
	}

	if err == nil {
		acc, ok := data.(*NotificationContent)
		if ok {
			return acc, nil
		}
	}

	nc := NewNotificationContent()
	nc.TypeConstant = typeConstant
	nc.TargetId = targetId
	if err := nc.FindByTarget(); err != nil {
		return nil, err
	}

	if err := a.SetToCache(nc); err != nil {
		return nil, err
	}

	return nc, nil
}

func (a *NotificationContentCache) SetToCache(nc *NotificationContent) error {
	ck := cacheKey(nc.TypeConstant, nc.TargetId)

	if err := a.typeConstantTargetId.Set(ck, nc); err != nil {
		return err
	}

	return nil
}

func cacheKey(typeConstant string, targetId int64) string {
	return fmt.Sprintf("%s_%d", typeConstant, targetId)
}
