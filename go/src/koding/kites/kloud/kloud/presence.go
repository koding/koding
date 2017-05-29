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

	// fethces sessions
	SessionFetcher func(string) (*models.Session, error)

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
		pingProvider:   p,
		SessionFetcher: modelhelper.GetSession,
		pingcache:      c,
	}
}

// Collect publishes presence requests
func (p *PresenceCollector) Collect(handler kite.HandlerFunc) kite.HandlerFunc {
	return func(r *kite.Request) (interface{}, error) {
		go func() {
			if r.Auth == nil || r.Auth.Type != "sessionID" {
				return
			}

			if _, err := p.pingcache.Get(r.Auth.Key); err != cache.ErrNotFound {
				return
			}

			ses, err := p.SessionFetcher(r.Auth.Key)
			if err != nil {
				return
			}

			if err := p.pingProvider.Ping(ses.Username, ses.GroupName); err != nil {
				r.LocalKite.Log.Error("err while sending ping req", err)
				return
			}
			p.pingcache.Set(r.Auth.Key, struct{}{})
		}()
		return handler(r)
	}
}
