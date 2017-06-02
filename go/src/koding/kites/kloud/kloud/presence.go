package kloud

import (
	"koding/db/models"
	"time"

	"koding/db/mongodb/modelhelper"

	"github.com/koding/cache"
	"github.com/koding/kite"
)

// PresenceCollector collects presence information
type PresenceCollector struct {
	// pingProvider sends ping requests
	pingProvider pinger

	// GroupFetcher fetches group from database with given kite request.
	GroupFetcher func(*kite.Request) (*models.Group, error)

	pingcache cache.Cache
}

type pinger interface {
	Ping(string, string) error
}

// NewPresenceCollector creates a new presence collector
func NewPresenceCollector(p pinger) *PresenceCollector {

	c := cache.NewMemoryWithTTL(time.Minute)
	c.StartGC(time.Second * 10)

	return &PresenceCollector{
		pingProvider: p,
		GroupFetcher: getGroup,
		pingcache:    c,
	}
}

// Collect publishes presence requests
func (p *PresenceCollector) Collect(handler kite.HandlerFunc) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		cacheKey := getCacheKey(r)

		if _, err := p.pingcache.Get(cacheKey); err != cache.ErrNotFound {
			return handler(r)
		}

		group, err := p.GroupFetcher(r)
		if err != nil || group == nil {
			return handler(r)
		}

		if err := p.pingProvider.Ping(r.Username, group.Slug); err == nil {
			p.pingcache.Set(cacheKey, struct{}{})
		}

		return handler(r)
	}
}

func getGroup(r *kite.Request) (*models.Group, error) {
	opts := &modelhelper.LookupGroupOptions{
		Username:    r.Username,
		KiteID:      r.Client.ID,
		ClientURL:   r.Client.URL,
		Environment: r.Client.Environment,
	}

	return modelhelper.LookupGroup(opts)
}

func getCacheKey(r *kite.Request) string {
	return r.Username + "_" + r.Client.ID + "_" + r.Client.URL + "_" + r.Client.Environment
}
