package exporter

import (
	mongomodels "koding/db/models"
	"koding/db/mongodb/modelhelper"
	"time"

	"github.com/koding/cache"
)

func newGroupCache() *groupCache {
	slugCache := cache.NewMemoryWithTTL(time.Second * 5)
	slugCache.StartGC(time.Minute)
	return &groupCache{
		slug: slugCache,
	}
}

// groupCache caches the group.
type groupCache struct {
	slug cache.Cache
}

func (s *groupCache) BySlug(slug string) (*mongomodels.Group, error) {
	data, err := s.slug.Get(slug)
	if err != nil && err != cache.ErrNotFound {
		return nil, err
	}

	if err == nil {
		if group, ok := data.(*mongomodels.Group); ok {
			return group, nil
		}
	}

	group, err := modelhelper.GetGroup(slug)
	if err != nil {
		return nil, err
	}

	if err := s.SetToCache(group); err != nil {
		return nil, err
	}

	return group, nil
}

func (s *groupCache) SetToCache(group *mongomodels.Group) error {
	return s.slug.Set(group.Slug, group)
}
