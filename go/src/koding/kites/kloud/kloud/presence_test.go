package kloud

import (
	"koding/db/models"
	"testing"

	mgo "gopkg.in/mgo.v2"

	"github.com/koding/cache"
	"github.com/koding/kite"
)

// type ping struct {
// 	username string
// 	team     string
// }

type pingCounter struct {
	count int
}

func (p *pingCounter) Ping(_ string, _ string) error {
	p.count++
	return nil
}
func TestPresenceCollector_Collect(t *testing.T) {
	type fields struct {
		pingProvider   *pingCounter
		SessionFetcher func(string) (*models.Session, error)
		pingcache      cache.Cache
	}

	mySessionIDCache := cache.NewMemory()
	mySessionIDCache.Set("my-session-id", struct{}{})

	tests := []struct {
		name       string
		fields     *fields
		args       *kite.Request
		wantedPing int
	}{
		{
			name: "can not get session",
			fields: &fields{
				pingProvider:   &pingCounter{},
				SessionFetcher: func(clientId string) (*models.Session, error) { return nil, mgo.ErrNotFound },
				pingcache:      cache.NewMemory(),
			},
			args: &kite.Request{
				Auth: &kite.Auth{
					Type: "sessionID",
					Key:  "my-session-id",
				},
			},
			wantedPing: 0,
		},
		{
			name: "nil auth",
			fields: &fields{
				pingProvider:   &pingCounter{},
				SessionFetcher: func(clientId string) (*models.Session, error) { return nil, nil },
				pingcache:      cache.NewMemory(),
			},
			args: &kite.Request{
				Auth: nil,
			},
			wantedPing: 0,
		},
		{
			name: "invalid auth",
			fields: &fields{
				pingProvider:   &pingCounter{},
				SessionFetcher: func(clientId string) (*models.Session, error) { return nil, nil },
				pingcache:      cache.NewMemory(),
			},
			args: &kite.Request{
				Auth: &kite.Auth{
					Type: "",
					Key:  "",
				},
			},
			wantedPing: 0,
		},
		{
			name: "duplicate request",
			fields: &fields{
				pingProvider:   &pingCounter{},
				SessionFetcher: func(clientId string) (*models.Session, error) { return nil, nil },
				pingcache:      mySessionIDCache,
			},
			args: &kite.Request{
				Auth: &kite.Auth{
					Type: "sessionID",
					Key:  "my-session-id",
				},
			},
			wantedPing: 0,
		},
		{
			name: "duplicate request",
			fields: &fields{
				pingProvider:   &pingCounter{},
				SessionFetcher: func(clientId string) (*models.Session, error) { return nil, nil },
				pingcache:      mySessionIDCache,
			},
			args: &kite.Request{
				Auth: &kite.Auth{
					Type: "sessionID",
					Key:  "my-session-id",
				},
			},
			wantedPing: 0,
		},
		{
			name: "cant fetch session",
			fields: &fields{
				pingProvider: &pingCounter{},
				SessionFetcher: func(clientId string) (*models.Session, error) {
					return &models.Session{Username: "test1u", GroupName: "test1"}, nil
				},
				pingcache: cache.NewMemory(),
			},
			args: &kite.Request{
				Auth: &kite.Auth{
					Type: "sessionID",
					Key:  "my-session-id",
				},
			},
			wantedPing: 0,
		},
		{
			name: "cant send ping",
			fields: &fields{
				pingProvider: &pingCounter{},
				SessionFetcher: func(clientId string) (*models.Session, error) {
					return &models.Session{Username: "test1u", GroupName: "test1"}, nil
				},
				pingcache: cache.NewMemory(),
			},
			args: &kite.Request{
				Auth: &kite.Auth{
					Type: "sessionID",
					Key:  "my-session-id",
				},
			},
			wantedPing: 0,
		},
		{
			name: "successful publish",
			fields: &fields{
				pingProvider: &pingCounter{},
				SessionFetcher: func(clientId string) (*models.Session, error) {
					return &models.Session{Username: "test1u", GroupName: "test1"}, nil
				},
				pingcache: cache.NewMemory(),
			},
			args: &kite.Request{
				Auth: &kite.Auth{
					Type: "sessionID",
					Key:  "my-session-id",
				},
			},
			wantedPing: 0,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p := &PresenceCollector{
				pingProvider:   tt.fields.pingProvider,
				SessionFetcher: tt.fields.SessionFetcher,
				pingcache:      tt.fields.pingcache,
			}
			collector := p.Collect(func(r *kite.Request) (interface{}, error) { return nil, nil })
			_, err := collector.ServeKite(tt.args)
			if err != nil {
				t.Errorf("collector.ServeKite() = %v, want %v", err, nil)
			}

			if tt.wantedPing != tt.fields.pingProvider.count {
				t.Errorf("tt.wantedPing = %v, want %v", tt.fields.pingProvider.count, tt.wantedPing)
			}
		})
	}
}
