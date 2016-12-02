package socialapi

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"sync"
)

const maxBodyLen = 2 << 20 // 2 MiB

// contextKey is a value for use with context.WithValue.
type contextKey struct {
	name string
}

// SessionContextKey is a context key. It can be used in
// HTTP handlers to attach a client session to a request.
//
// The session is then read by the Transport and used
// for authentication.
//
// The associated value will be of *Session type.
var SessionContextKey = &contextKey{"client-session"}

// Session represents a user session.
type Session struct {
	// ClientID is an ID of the session.
	ClientID string

	// Username of the user holding the session.
	Username string

	// Team, which the user belongs to.
	Team string
}

// Key is used for SessionCache to cache sessions by keys.
func (s *Session) Key() string {
	return s.Team + "/" + s.Username
}

// Valid implements the stack.Validator interface.
func (s *Session) Valid() error {
	if s == nil {
		return errors.New("session is missing")
	}
	if s.ClientID == "" {
		return errors.New("empty client ID")
	}
	return nil
}

// AuthFunc is used to fetch session information.
//
// When Refresh is true, AuthFunc must obtain
// a session directly from an authorisation
// endpoint, in case it was cached.
type AuthFunc func(*AuthOptions) (*Session, error)

// AuthOptions represents the arguments for AuthFunc.
type AuthOptions struct {
	// Session represents either a valid session or
	// Username/Team pair to request a new session
	// from AuthFunc.
	//
	// If the session is valid and Refresh false,
	// then it should be returned and AuthFunc
	// should behave as nop.
	//
	// When Refresh is true, AuthFunc should request
	// new session, no matter whether Session is
	// valid or not.
	Session *Session

	// Refresh requests to refresh a session when true.
	Refresh bool

	// Request is a copy of the request, for which
	// we're building authorisation.
	Request *http.Request
}

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

	session, err := s.Auth(opts)

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

type httpTransport interface {
	http.RoundTripper
	httpRequestCanceler
	httpIdleConnectionsCloser
}

type httpRequestCanceler interface {
	CancelRequest(*http.Request)
}

type httpIdleConnectionsCloser interface {
	CloseIdleConnections()
}

// nopCloser is like ioutil.NopCloser, but wraps io.ReadSeeker.
type nopCloser struct{ io.ReadSeeker }

func (nopCloser) Close() (_ error) { return }

var _ io.ReadSeeker = nopCloser{bytes.NewReader(nil)}

// Transport is a signing transport that
// authorizes each request with jSession.clientId.
type Transport struct {
	http.RoundTripper          // a transport to use; required
	AuthFunc          AuthFunc // clientID authorisation to use; required
	Host              string   // original Host name, overwrites req.Host; optional
	RetryNum          int      // number of retries in case of temporary failures; optional
}

var _ httpTransport = (*Transport)(nil)

// RoundTrip implements the http.RoundTripper interface.
func (t *Transport) RoundTrip(req *http.Request) (*http.Response, error) {
	if t.AuthFunc == nil {
		panic("socialapi: AuthFunc is nil")
	}

	reqCopy := copyRequest(req) // per RoundTripper contract

	switch req.Body.(type) {
	case nil:
	case io.ReadSeeker:
	default:
		p, err := ioutil.ReadAll(io.LimitReader(reqCopy.Body, maxBodyLen))
		if err != nil {
			return nil, err // non-retryable
		}

		reqCopy.Body = nopCloser{bytes.NewReader(p)}
	}

	var refresh bool
	var lastErr error
	var session *Session

	if s, ok := reqCopy.Context().Value(SessionContextKey).(*Session); ok {
		session = s
	}

	for attempts := t.retryNum(); attempts > 0; attempts-- {
		if reqCopy.Body != nil {
			if _, err := reqCopy.Body.(io.ReadSeeker).Seek(0, io.SeekStart); err != nil {
				return nil, err // non-retryable
			}
		}

		opts := &AuthOptions{
			Session: session,
			Refresh: refresh,
			Request: reqCopy,
		}

		s, err := t.AuthFunc(opts)
		if err != nil {
			return nil, err // non-retryable
		}

		if err := s.Valid(); err != nil {
			return nil, err // non-retryable
		}

		session = s
		refresh = false

		reqCopy.Header.Set("Authorization", "Bearer "+session.ClientID)
		if t.Host != "" {
			reqCopy.Host = t.Host
		}

		resp, err := t.RoundTripper.RoundTrip(reqCopy)
		if e, ok := err.(net.Error); ok && (e.Temporary() || e.Timeout()) {
			lastErr = err
			continue // retry
		}

		if err != nil {
			return nil, err // non-retryable
		}

		if resp.StatusCode == http.StatusUnauthorized {
			lastErr = errors.New(http.StatusText(resp.StatusCode))
			refresh = true
			continue // retry and force new session
		}

		return resp, nil
	}

	return nil, fmt.Errorf("socialapi: error sending request: %v", lastErr)
}

func (t *Transport) CancelRequest(req *http.Request) {
	if rc, ok := t.RoundTripper.(httpRequestCanceler); ok {
		rc.CancelRequest(req)
	}
}

func (t *Transport) CloseIdleConnections() {
	if icl, ok := t.RoundTripper.(httpIdleConnectionsCloser); ok {
		icl.CloseIdleConnections()
	}
}

func (t *Transport) retryNum() int {
	if t.RetryNum > 0 {
		return t.RetryNum
	}
	return 3
}

func copyURL(u *url.URL) *url.URL {
	uCopy := *u
	if u.User != nil {
		userCopy := *u.User
		uCopy.User = &userCopy
	}

	return &uCopy
}

func copyRequest(req *http.Request) *http.Request {
	reqCopy := new(http.Request)
	*reqCopy = *req
	reqCopy.URL = copyURL(req.URL)
	reqCopy.Header = make(http.Header, len(req.Header))
	for k, s := range req.Header {
		reqCopy.Header[k] = append([]string(nil), s...)
	}
	return reqCopy
}
