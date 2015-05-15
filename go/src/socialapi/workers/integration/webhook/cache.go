package webhook

import "github.com/koding/cache"

const cacheSize = 10000

var Cache *StaticCache

func init() {
	Cache = &StaticCache{
		Integration: &IntegrationCache{
			name: cache.NewLRU(cacheSize),
		},
		ChannelIntegration: &ChannelIntegrationCache{
			token: cache.NewLRU(cacheSize),
		},
	}
}

type StaticCache struct {
	Integration        *IntegrationCache
	ChannelIntegration *ChannelIntegrationCache
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

//////////// ChannelIntegrationCache ///////////////
type ChannelIntegrationCache struct {
	token cache.Cache
}

func (i *ChannelIntegrationCache) ByToken(token string) (*ChannelIntegration, error) {
	data, err := i.token.Get(token)
	if err == nil {
		in, ok := data.(*ChannelIntegration)
		if ok {
			return in, nil
		}
	}

	if err != cache.ErrNotFound {
		return nil, err
	}

	in := NewChannelIntegration()
	if err := in.ByToken(token); err != nil {
		return nil, err
	}

	if err := i.SetToCache(in); err != nil {
		return nil, err
	}

	return in, nil
}

func (i *ChannelIntegrationCache) SetToCache(ci *ChannelIntegration) error {
	return i.token.Set(ci.Token, ci)
}
