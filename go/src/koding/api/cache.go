package api

import (
	"errors"
	"sync"
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
	Get(*Session) (*Session, error)

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
	// If nil, in-memory map is going to be used instead.
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
	if s.AuthFunc == nil {
		panic("api: AuthFunc is nil")
	}

	session := opts.Session

	if session == nil {
		return nil, errors.New("cannot determine user session")
	}

	// Early return - return existing session if it's valid
	// and we were not ask to invalidate it.
	if err := session.Valid(); err == nil && !opts.Refresh {
		return session, nil
	}

	if !opts.Refresh {
		cachedSession, err := s.Storage.Get(session)

		switch err {
		case ErrSessionNotFound:
			// continue
		case nil:
			return cachedSession, nil
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

// TODO(rjeczalik): replace with koding/cache
type defaultStorage struct {
	cacheMu sync.RWMutex
	cache   map[string]*Session
}

var _ Storage = (*defaultStorage)(nil)

func newDefaultStorage() *defaultStorage {
	return &defaultStorage{
		cache: make(map[string]*Session),
	}
}

func (ds *defaultStorage) Get(s *Session) (*Session, error) {
	ds.cacheMu.Lock()
	session, ok := ds.cache[s.Key()]
	ds.cacheMu.Unlock()

	if !ok {
		return nil, ErrSessionNotFound
	}

	return session, nil
}

func (ds *defaultStorage) Set(s *Session) error {
	ds.cacheMu.Lock()
	ds.cache[s.Key()] = s
	ds.cacheMu.Unlock()

	return nil
}

func (ds *defaultStorage) Delete(s *Session) error {
	ds.cacheMu.Lock()
	delete(ds.cache, s.Key())
	ds.cacheMu.Unlock()

	return nil
}
