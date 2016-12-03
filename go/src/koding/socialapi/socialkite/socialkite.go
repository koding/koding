package socialkite

import (
	"sync"

	"koding/kites/kloud/stack"
	"koding/socialapi"
)

// Kite is an interface for kite.Kite, that is used
// to make RPC calls.
type Kite interface {
	Call(method string, req, resp interface{}) error
}

// KloudAuth provides socialapi.AuthFunc that is
// backed by kite RPC.
type KloudAuth struct {
	Kite    Kite              // kite transport to use; required
	Storage socialapi.Storage // storage for cache to use; optional

	once sync.Once
	auth socialapi.AuthFunc
}

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
