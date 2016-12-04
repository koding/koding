package socialkite

import (
	"sync"
	"time"

	"github.com/koding/kite"

	"koding/kites/config"
	"koding/kites/kloud/stack"
	"koding/socialapi"
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

// KloudAuth provides socialapi.AuthFunc that is
// backed by kite RPC.
type KloudAuth struct {
	Kite    Kite              // kite transport to use; required
	Storage socialapi.Storage // storage for cache to use; optional

	once sync.Once
	auth socialapi.AuthFunc
}

var _ socialapi.AuthFunc = (&KloudAuth{}).Auth

func (ka *KloudAuth) init() {
	ka.once.Do(ka.initAuth)
}

func (ka *KloudAuth) initAuth() {
	if ka.Storage != nil {
		cache := socialapi.NewCache(ka.rpcAuth)
		cache.Storage = ka.Storage
		ka.auth = cache.Auth
	} else {
		ka.auth = ka.rpcAuth
	}
}

// Auth obtains user session by calling "auth.login" method over Kite transport.
func (ka *KloudAuth) Auth(opts *socialapi.AuthOptions) (*socialapi.Session, error) {
	ka.init()
	return ka.auth(opts)
}

func (ka *KloudAuth) rpcAuth(opts *socialapi.AuthOptions) (*socialapi.Session, error) {
	var req = &stack.LoginRequest{GroupName: opts.Session.Team}
	var resp stack.LoginResponse

	if err := ka.Kite.Call("auth.login", req, &resp); err != nil {
		return nil, err
	}

	return &socialapi.Session{
		ClientID: resp.ClientID,
		// TODO(rjeczalik): add Username field to stack.LoginResponse
		// Username: resp.Username,
		Username: opts.Session.Username,
		Team:     resp.GroupName,
	}, nil
}

// Storage is wrapper for config.Cache that implements socialapi.Storage.
type Storage struct {
	Cache *config.Cache
}

var _ socialapi.Storage = (*Storage)(nil)

// Get implements the socialapi.Storage interface.
func (st *Storage) Get(s *socialapi.Session) error {
	var sessions map[string]socialapi.Session

	if err := st.Cache.GetValue("auth.sessions", &sessions); err != nil {
		return err
	}

	session, ok := sessions[s.Key()]
	if !ok {
		return socialapi.ErrSessionNotFound
	}

	*s = session

	return nil
}

// Set implements the socialapi.Storage interface.
func (st *Storage) Set(s *socialapi.Session) error {
	sessions := make(map[string]socialapi.Session)

	if err := st.Cache.GetValue("auth.sessions", &sessions); err != nil {
		return err
	}

	sessions[s.Key()] = *s

	return st.Cache.SetValue("auth.sessions", sessions)
}

// Delete implements the socialapi.Storage interface.
func (st *Storage) Delete(s *socialapi.Session) error {
	sessions := make(map[string]socialapi.Session)

	if err := st.Cache.GetValue("auth.sessions", &sessions); err != nil {
		return err
	}

	delete(sessions, s.Key())

	return st.Cache.SetValue("auth.sessions", sessions)
}
