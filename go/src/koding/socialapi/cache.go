package socialapi

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
	Get(*Session) error

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

	cacheMu sync.RWMutex
	cache   map[string]*Session
}

// NewSessionCache gives new SessionCache value.
func NewSessionCache(fn AuthFunc) *SessionCache {
	return &SessionCache{
		AuthFunc: fn,
		cache:    make(map[string]*Session),
	}
}

// Auth is a method, which method selector can be used
// as a AuthFunc value, like:
//
//   cache := socialapi.NewSessionCache(authFn)
//
//   t := &socialapi.Transport{
//       AuthFunc: cache.Auth,
//   }
//
func (s *SessionCache) Auth(opts *AuthOptions) (*Session, error) {
	if s.AuthFunc == nil {
		panic("socialapi: AuthFunc is nil")
	}

	session := opts.Session

	// Early return - return existing session if it's valid
	// and we were not ask to invalidate it.
	if err := session.Valid(); err == nil && !opts.Refresh {
		return session, nil
	}

	if session == nil {
		return nil, errors.New("cannot determine user session")
	}

	if !opts.Refresh {
		s.cacheMu.RLock()
		err := s.get(session)
		s.cacheMu.RUnlock()

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
	//
	s.cacheMu.Lock()
	if opts.Refresh {
		_ = s.delete(session)
	}
	if err == nil {
		_ = s.set(session)
	}
	s.cacheMu.Unlock()

	return session, err
}

func (s *SessionCache) get(session *Session) error {
	if s.Storage != nil {
		return s.Storage.Get(session)
	}

	sess, ok := s.cache[session.Key()]
	if !ok {
		return ErrSessionNotFound
	}

	*session = *sess

	return nil
}

func (s *SessionCache) set(session *Session) error {
	if s.Storage != nil {
		return s.Storage.Set(session)
	}

	s.cache[session.Key()] = session

	return nil
}

func (s *SessionCache) delete(session *Session) error {
	if s.Storage != nil {
		return s.Storage.Delete(session)
	}

	delete(s.cache, session.Key())

	return nil
}
