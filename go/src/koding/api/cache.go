package api

import (
	"errors"

	"github.com/koding/cache"
)

// ErrSessionNotFound is returned by Storage.Get
// when requested session was not found.
var ErrSessionNotFound = errors.New("session not found")

// Storage is an interface for external session storage.
type Storage interface {
	// Get gets a session.
	//
	// It returns ErrSessionNotFound if requested
	// session was not cached.
	Get(*User) (*Session, error)

	// Set sets a session.
	//
	// It overwrites any session that may exist
	// already.
	Set(*Session) error

	// Delete deletes a session.
	//
	// If requested session does not exist,
	// the method is a nop.
	Delete(*Session) error
}

// SessionCache is a wrapper for AuthFunc that caches
// sessions and invalidates them when requested.
type SessionCache struct {
	// AuthFunc is a mean to obtain session information.
	//
	// It is only called when a session was requested
	// for a user/team pair that is not cached yet.
	// Or when we were explicitly asked to request
	// new session with Refresh set to true.
	AuthFunc AuthFunc

	// Storage is an external storage for storing session.
	//
	// If nil, a default, in-memory map is going to be used instead.
	Storage Storage
}

// NewCache gives new SessionCache value.
func NewCache(fn AuthFunc) *SessionCache {
	return &SessionCache{
		AuthFunc: fn,
		Storage:  newDefaultStorage(),
	}
}

// Auth is a method, which method selector can be used
// as a AuthFunc value, like:
//
//   cache := api.NewSessionCache(authFn)
//
//   t := &api.Transport{
//       AuthFunc: cache.Auth,
//   }
//
func (s *SessionCache) Auth(opts *AuthOptions) (*Session, error) {
	if !opts.Refresh {
		session, err := s.Storage.Get(opts.User)

		switch err {
		case ErrSessionNotFound:
			// continue
		case nil:
			return session, nil
		default:
			return nil, err
		}
	}

	session, err := s.AuthFunc(opts)

	// TODO(rjeczalik): for now we ignore storage errors,
	// maybe we should handle them (fallback to memory?).
	//
	// - if storage failed to delete invalidated session,
	//   then the worst case any concurrent requests could
	//   try to use it again at most once.
	//
	// - if set failed, we are going to request session again
	//   for the next request
	//
	// System-wise Kloud uses in-memory cache while KD and Klient
	// use BoltDB-backed cache. Since the latter two take exclusive
	// lock of the database file, the only reason storage can
	// fail are filesystem errors - there is no recovery from
	// that, and falling back to memory makes sense only for
	// Klient.
	if opts.Refresh {
		_ = s.Storage.Delete(session)
	}
	if err == nil {
		_ = s.Storage.Set(session)
	}

	return session, err
}

type defaultStorage struct {
	cache cache.Cache
}

var _ Storage = (*defaultStorage)(nil)

func newDefaultStorage() *defaultStorage {
	return &defaultStorage{
		cache: cache.NewLRU(2000),
	}
}

func (ds *defaultStorage) Get(u *User) (*Session, error) {
	s, err := ds.cache.Get(u.String())

	if err == cache.ErrNotFound {
		return nil, ErrSessionNotFound
	}
	if err != nil {
		return nil, err
	}

	return s.(*Session), nil
}

func (ds *defaultStorage) Set(s *Session) error {
	return ds.cache.Set(s.User.String(), s)
}

func (ds *defaultStorage) Delete(s *Session) error {
	switch err := ds.cache.Delete(s.User.String()); err {
	case cache.ErrNotFound:
		return nil
	default:
		return err
	}
}
