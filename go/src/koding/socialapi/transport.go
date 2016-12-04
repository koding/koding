package socialapi

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"net/url"
	"strings"
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

// DirectorContextKey is a context key. It can be used
// in HTTP handlers to obtain an original request
// before it was edited by a DirectorTransport.
//
// The associated value will be of *http.Request type.
var DirectorContextKey = &contextKey{"original-request"}

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

// WithRequest attaches the session to the given request.
func (s *Session) WithRequest(req *http.Request) *http.Request {
	return req.WithContext(context.WithValue(req.Context(), SessionContextKey, s))
}

func (s *Session) writeTo(req *http.Request) {
	req.Header.Set("Authorization", "Bearer "+s.ClientID)
}

func (s *Session) readFrom(req *http.Request) {
	if auth := req.Header.Get("Authorization"); strings.HasPrefix(auth, "Bearer ") {
		s.ClientID = auth[len("Bearer "):]
	}
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

	// Error is the error that was the reason
	// of temporary failure received while trying
	// to sending request.
	//
	// Error is non-nil when request failed with
	// temporary error and Transport is retrying.
	Error error
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
	http.RoundTripper          // a transport to use; optional, by default http.DefaultClient.Transport
	AuthFunc          AuthFunc // clientID authorisation to use; required
	Host              string   // original Host name, overwrites req.Host; optional
	RetryNum          int      // number of retries in case of temporary failures; optional, by default 3
}

var _ httpTransport = (*Transport)(nil)

// NewSingleClient returns a HTTP transport that authenticates all
// requests with the given session.
//
// Session is expected to be have a valid clientID. In order to be
// able to refresh the session if it gets invalidated, the session
// must also contain Username / Team information.
//
// This is usefull for api clients that give no control over HTTP requests,
// like the swagger-generated ones (remote.api).
func (t *Transport) NewSingleClient(session *Session) http.RoundTripper {
	return &DirectorTransport{
		RoundTripper: t,
		Director: func(req *http.Request) {
			*req = *session.WithRequest(req)
		},
	}
}

// RoundTrip implements the http.RoundTripper interface.
func (t *Transport) RoundTrip(req *http.Request) (*http.Response, error) {
	session, ok := req.Context().Value(SessionContextKey).(*Session)
	if !ok {
		return t.roundTripper().RoundTrip(req)
	}

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

	for attempts := t.retryNum(); attempts >= 0; attempts-- {
		if reqCopy.Body != nil {
			if _, err := reqCopy.Body.(io.ReadSeeker).Seek(0, io.SeekStart); err != nil {
				return nil, err // non-retryable
			}
		}

		opts := &AuthOptions{
			Session: session,
			Refresh: refresh,
			Request: reqCopy,
			Error:   lastErr,
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

		session.writeTo(reqCopy)

		if t.Host != "" {
			reqCopy.Host = t.Host
		}

		resp, err := t.roundTripper().RoundTrip(reqCopy)
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
	if rc, ok := t.roundTripper().(httpRequestCanceler); ok {
		rc.CancelRequest(req)
	}
}

func (t *Transport) CloseIdleConnections() {
	if icl, ok := t.roundTripper().(httpIdleConnectionsCloser); ok {
		icl.CloseIdleConnections()
	}
}

func (t *Transport) roundTripper() http.RoundTripper {
	if t.RoundTripper != nil {
		return t.RoundTripper
	}

	if http.DefaultClient.Transport != nil {
		return http.DefaultClient.Transport
	}

	return http.DefaultTransport
}

func (t *Transport) retryNum() int {
	if t.RetryNum > 0 {
		return t.RetryNum
	}
	return 3
}

// DirectoryTransport is a Transport that modifies each request before
// passing it over to underlying round-tripper.
type DirectorTransport struct {
	http.RoundTripper                     // a transport to direct; required
	Director          func(*http.Request) // function that modifies request; required
}

var _ httpTransport = (*DirectorTransport)(nil)

// RoundTrip implements the http.RoundTripper interface.
func (dt *DirectorTransport) RoundTrip(req *http.Request) (*http.Response, error) {
	dt.Director(req)
	return dt.RoundTripper.RoundTrip(req)
}

func (dt *DirectorTransport) CancelRequest(req *http.Request) {
	if rc, ok := dt.RoundTripper.(httpRequestCanceler); ok {
		rc.CancelRequest(req)
	}
}

func (dt *DirectorTransport) CloseIdleConnections() {
	if icl, ok := dt.RoundTripper.(httpIdleConnectionsCloser); ok {
		icl.CloseIdleConnections()
	}
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
