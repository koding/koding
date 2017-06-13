package api

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/koding/cache"
)

func newGroupCache() *groupDataCache {
	slugCache := cache.NewMemoryWithTTL(time.Second * 5)
	slugCache.StartGC(time.Minute)
	return &groupDataCache{
		slug: slugCache,
	}
}

// groupDataCache caches the group.
type groupDataCache struct {
	slug cache.Cache
}

func (s *groupDataCache) BySlug(slug string) (*mongomodels.GroupData, error) {
	data, err := s.slug.Get(slug)
	if err != nil && err != cache.ErrNotFound {
		return nil, err
	}

	if err == nil {
		if group, ok := data.(*mongomodels.GroupData); ok {
			return group, nil
		}
	}

	return s.Refresh(slug)
}

func (s *groupDataCache) SetToCache(group *mongomodels.GroupData) error {
	return s.slug.Set(group.Slug, group)
}

func (s *groupDataCache) Refresh(slug string) (*mongomodels.GroupData, error) {
	groupData := &mongomodels.GroupData{}
	err := modelhelper.GetGroupData(slug, groupData)
	if err != nil {
		return nil, err
	}

	if err := s.SetToCache(groupData); err != nil {
		return nil, err
	}

	return groupData, nil
}
