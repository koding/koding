package kloud

import (
	"koding/db/models"
	"koding/db/mongodb/modelhelper"
	"koding/db/mongodb/modelhelper/modeltesthelper"
	"net"
	"net/http"
	"net/http/httptest"
	"socialapi/workers/presence/client"
	"testing"

	mgo "gopkg.in/mgo.v2"
	"gopkg.in/mgo.v2/bson"

	"github.com/koding/cache"
	"github.com/koding/kite"
	"github.com/koding/kite/protocol"
)

type pingCounter struct {
	count int
	err   error
}

func (p *pingCounter) Ping(_ string, _ string) error {
	if p.err == nil {
		p.count++
	}

	return p.err
}

func TestPresenceCollector(t *testing.T) {
	type fields struct {
		pingProvider *pingCounter
		GroupFetcher func(r *kite.Request) (*models.Group, error)
		pingcache    cache.Cache
	}

	duplicateKiteReq := &kite.Request{
		Username: "test",
		Client: &kite.Client{
			Kite: protocol.Kite{
				ID:          "my-client-id",
				Environment: "test",
			},
			URL: "https://my-client.url",
		},
	}

	mySessionIDCache := cache.NewMemory()
	mySessionIDCache.Set(getCacheKey(duplicateKiteReq), struct{}{})

	tests := []struct {
		name       string
		fields     *fields
		args       *kite.Request
		wantedPing int
	}{
		{
			name: "can not get session",
			fields: &fields{
				pingProvider: &pingCounter{},
				GroupFetcher: func(r *kite.Request) (*models.Group, error) { return nil, mgo.ErrNotFound },
				pingcache:    cache.NewMemory(),
			},
			args: &kite.Request{
				Username: "test",
				Client: &kite.Client{
					Kite: protocol.Kite{
						ID:          "my-client-id",
						Environment: "test",
					},
					URL: "https://my-client.url",
				},
			},
			wantedPing: 0,
		},
		{
			name: "duplicate request 1",
			fields: &fields{
				pingProvider: &pingCounter{},
				GroupFetcher: func(r *kite.Request) (*models.Group, error) { return nil, nil },
				pingcache:    mySessionIDCache,
			},
			args:       duplicateKiteReq,
			wantedPing: 0,
		},
		{
			name: "duplicate request 2",
			fields: &fields{
				pingProvider: &pingCounter{},
				GroupFetcher: func(r *kite.Request) (*models.Group, error) { return nil, nil },
				pingcache:    mySessionIDCache,
			},
			args:       duplicateKiteReq,
			wantedPing: 0,
		},
		{
			name: "cant fetch group",
			fields: &fields{
				pingProvider: &pingCounter{},
				GroupFetcher: func(r *kite.Request) (*models.Group, error) {
					return nil, mgo.ErrNotFound
				},
				pingcache: cache.NewMemory(),
			},
			args: &kite.Request{
				Username: "test",
				Client: &kite.Client{
					Kite: protocol.Kite{
						ID:          "my-client-id",
						Environment: "test",
					},
					URL: "https://my-client.url",
				},
			},
			wantedPing: 0,
		},
		{
			name: "cant send ping",
			fields: &fields{
				pingProvider: &pingCounter{err: net.InvalidAddrError("")},
				GroupFetcher: func(r *kite.Request) (*models.Group, error) {
					return &models.Group{Slug: "test1u"}, nil
				},
				pingcache: cache.NewMemory(),
			},
			args: &kite.Request{
				Username: "test",
				Client: &kite.Client{
					Kite: protocol.Kite{
						ID:          "my-client-id",
						Environment: "test",
					},
					URL: "https://my-client.url",
				},
			},
			wantedPing: 0,
		},
		{
			name: "successful publish",
			fields: &fields{
				pingProvider: &pingCounter{},
				GroupFetcher: func(r *kite.Request) (*models.Group, error) {
					return &models.Group{Slug: "test1u"}, nil
				},
				pingcache: cache.NewMemory(),
			},
			args: &kite.Request{
				Username: "test",
				Client: &kite.Client{
					Kite: protocol.Kite{
						ID:          "my-client-id",
						Environment: "test",
					},
					URL: "https://my-client.url",
				},
			},
			wantedPing: 1,
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			p := &PresenceCollector{
				pingProvider: tt.fields.pingProvider,
				GroupFetcher: tt.fields.GroupFetcher,
				pingcache:    tt.fields.pingcache,
			}
			collector := p.Collect(func(r *kite.Request) (interface{}, error) { return nil, nil })
			_, err := collector.ServeKite(tt.args)
			if err != nil {
				t.Fatalf("collector.ServeKite() = %v, want %v", err, nil)
			}

			if tt.wantedPing != tt.fields.pingProvider.count {
				t.Fatalf("tt.wantedPing = %v, want %v", tt.fields.pingProvider.count, tt.wantedPing)
			}
		})
	}
}
func TestPresenceCollectorIntegration(t *testing.T) {
	db := modeltesthelper.NewMongoDB(t)
	defer db.Close()

	username := bson.NewObjectId().Hex()
	user, err := modeltesthelper.CreateUserWithMachine(username)
	if err != nil {
		t.Fatalf("modeltesthelper.CreateUser() = %v, want %v", err, nil)
	}
	defer modelhelper.RemoveUser(user.Name)

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {}))
	defer ts.Close()

	presenceClient := client.NewInternal(ts.URL)
	presenceCollector := NewPresenceCollector(presenceClient).Collect(func(r *kite.Request) (interface{}, error) { return nil, nil })

	kiteReq := &kite.Request{
		Username: username,
		Client: &kite.Client{
			Kite: protocol.Kite{
				ID:          "my-client-id",
				Environment: "test",
			},
			URL: "https://my-client.url",
		},
	}
	if _, err := presenceCollector.ServeKite(kiteReq); err != nil {
		t.Fatalf("presenceCollector.ServeKite(kiteReq) = %v, want %v", err, nil)
	}
}
