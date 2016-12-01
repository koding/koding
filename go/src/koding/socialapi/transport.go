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

// Session represents
type Session struct {
	// ClientID
	ClientID string

	// Username
	Username string

	// Team
	Team string
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

// AuthFunc
type AuthFunc func(*AuthOptions) (*Session, error)

type cacheKey struct{ username, team string }

// SessionCache
type SessionCache struct {
	AuthFunc AuthFunc

	cacheMu sync.RWMutex
	cache   map[cacheKey]*Session
}

func NewSessionCache(fn AuthFunc) *SessionCache {
	return &SessionCache{
		AuthFunc: fn,
		cache:    make(map[cacheKey]*Session),
	}
}

// Auth
func (s *SessionCache) Auth(opts *AuthOptions) (*Session, error) {
	if s.AuthFunc == nil {
		panic("socialapi: AuthFunc is nil")
	}

	// Early return - return existing session if it's valid
	// and we were not ask to invalidate it.
	if err := opts.Session.Valid(); err == nil && !opts.Refresh {
		return opts.Session, nil
	}

	if opts.Session == nil {
		return nil, errors.New("cannot determine user session")
	}

	key := cacheKey{
		username: opts.Session.Username,
		team:     opts.Session.Team,
	}

	if !opts.Refresh {
		s.cacheMu.RLock()
		session, ok := s.cache[key]
		s.cacheMu.RUnlock()

		if ok {
			return session, nil
		}
	}

	session, err := s.Auth(opts)

	s.cacheMu.Lock()
	if opts.Refresh {
		delete(s.cache, key)
	}
	if err == nil {
		s.cache[key] = session
	}
	s.cacheMu.Unlock()

	return session, err
}

// AuthOptions
type AuthOptions struct {
	// Session
	Session *Session

	// Refresh
	Refresh bool

	// Request
	Request *http.Request
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
	http.RoundTripper

	// Host
	Host string

	// RetryNum
	RetryNum int

	// AuthFunc
	AuthFunc AuthFunc
}

var _ httpTransport = (*Transport)(nil)

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
