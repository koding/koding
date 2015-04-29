package webhook

import "github.com/koding/cache"

const cacheSize = 10000

var Cache *StaticCache

func init() {
	Cache = &StaticCache{
		Integration: &IntegrationCache{
			name: cache.NewLRU(cacheSize),
		},
	}
}

type StaticCache struct {
	Integration *IntegrationCache
}

type IntegrationCache struct {
	name cache.Cache
}

func (i *IntegrationCache) ByName(name string) (*Integration, error) {
	data, err := i.name.Get(name)
	if err == nil {
		in, ok := data.(*Integration)
		if ok {
			return in, nil
		}
	}

	if err != cache.ErrNotFound {
		return nil, err
	}

	in := NewIntegration()
	if err := in.ByName(name); err != nil {
		return nil, err
	}

	if err := i.SetToCache(in); err != nil {
		return nil, err
	}

	return in, nil
}

func (i *IntegrationCache) SetToCache(in *Integration) error {
	return i.name.Set(in.Name, in)
}
