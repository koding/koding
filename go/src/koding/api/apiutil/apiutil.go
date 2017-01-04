package apiutil

import (
	"sync"
	"time"

	"github.com/koding/kite"

	"koding/api"
	"koding/kites/config"
	"koding/kites/kloud/stack"
	"koding/klient/storage"
)

// Kite is an interface for kite.Kite, that is used
// to make RPC calls.
type Kite interface {
	Call(method string, req, resp interface{}) error
}

// LazyKite is a wrapper for Client that dials the
// kite on the first request.
type LazyKite struct {
	Client      *kite.Client  // kite client to use; required
	DialTimeout time.Duration // max dial time; 30s by default
	CallTimeout time.Duration // max call time; 60s by default

	mu     sync.Mutex
	dialed bool
}

var _ Kite = (*LazyKite)(nil)

// Call implements the Kite interface.
func (lk *LazyKite) Call(method string, req, resp interface{}) error {
	if err := lk.init(); err != nil {
		return err
	}

	r, err := lk.Client.TellWithTimeout(method, lk.callTimeout(), req)
	if err != nil {
		return err
	}

	if resp != nil {
		return r.Unmarshal(resp)
	}

	return nil
}

func (lk *LazyKite) init() error {
	lk.mu.Lock()
	defer lk.mu.Unlock()

	if !lk.dialed {
		if err := lk.Client.DialTimeout(lk.dialTimeout()); err != nil {
			return err
		}

		lk.dialed = true
	}

	return nil
}

func (lk *LazyKite) dialTimeout() time.Duration {
	if lk.DialTimeout != 0 {
		return lk.DialTimeout
	}
	return 30 * time.Second
}

func (lk *LazyKite) callTimeout() time.Duration {
	if lk.CallTimeout != 0 {
		return lk.CallTimeout
	}
	return 60 * time.Second
}

// KloudAuth provides api.AuthFunc that is
// backed by kite RPC.
type KloudAuth struct {
	Kite    Kite        // kite transport to use; required
	Storage api.Storage // storage for cache to use; optional

	once sync.Once
	auth api.AuthFunc
}

var _ api.AuthFunc = (&KloudAuth{}).Auth

func (ka *KloudAuth) init() {
	ka.once.Do(ka.initAuth)
}

func (ka *KloudAuth) initAuth() {
	if ka.Storage != nil {
		cache := api.NewCache(ka.rpcAuth)
		cache.Storage = ka.Storage
		ka.auth = cache.Auth
	} else {
		ka.auth = ka.rpcAuth
	}
}

// Auth obtains user session by calling "auth.login" method over Kite transport.
func (ka *KloudAuth) Auth(opts *api.AuthOptions) (*api.Session, error) {
	ka.init()
	return ka.auth(opts)
}

func (ka *KloudAuth) rpcAuth(opts *api.AuthOptions) (*api.Session, error) {
	var req = &stack.LoginRequest{GroupName: opts.User.Team}
	var resp stack.LoginResponse

	if err := ka.Kite.Call("auth.login", req, &resp); err != nil {
		return nil, err
	}

	return &api.Session{
		ClientID: resp.ClientID,
		User: &api.User{
			Username: resp.Username,
			Team:     resp.GroupName,
		},
	}, nil
}

// Storage is wrapper for config.Cache that implements api.Storage.
type Storage struct {
	Cache *config.Cache
}

var _ api.Storage = (*Storage)(nil)

// Get implements the api.Storage interface.
func (st *Storage) Get(u *api.User) (*api.Session, error) {
	var sessions map[string]api.Session

	err := st.Cache.GetValue("auth.sessions", &sessions)
	if err == storage.ErrKeyNotFound {
		return nil, api.ErrSessionNotFound
	}
	if err != nil {
		return nil, err
	}

	session, ok := sessions[u.String()]
	if !ok {
		return nil, api.ErrSessionNotFound
	}

	return &session, nil
}

// Set implements the api.Storage interface.
func (st *Storage) Set(s *api.Session) error {
	sessions := make(map[string]api.Session)

	if err := st.Cache.GetValue("auth.sessions", &sessions); err != nil {
		return err
	}

	sessions[s.User.String()] = *s

	return st.Cache.SetValue("auth.sessions", sessions)
}

// Delete implements the api.Storage interface.
func (st *Storage) Delete(s *api.Session) error {
	sessions := make(map[string]api.Session)

	if err := st.Cache.GetValue("auth.sessions", &sessions); err != nil {
		return err
	}

	delete(sessions, s.User.String())

	return st.Cache.SetValue("auth.sessions", sessions)
}
