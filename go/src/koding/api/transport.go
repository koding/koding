package api

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"io/ioutil"
	"net"
	"net/http"
	"net/http/httputil"
	"net/url"
	"strings"
	"sync"

	"github.com/koding/logging"
)

const maxBodyLen = 2 << 20 // 2 MiB

var defaultLog = logging.NewCustom("api-transport", false)

// contextKey is a value for use with context.WithValue.
type contextKey struct {
	name string
}

// UserContextKey is a context key. It can be used in
// HTTP handlers to attach a client session to a request.
//
// The session is then read by the Transport and used
// for authentication.
//
// The associated value will be of *User type.
var UserContextKey = &contextKey{"client-session"}

// UserFunc is used to extract a user, which requires authentication,
// from a request.
type UserFunc func(*http.Request) *User

// User represents a user, which is going to be authenticated.
type User struct {
	Username string // name of the user
	Team     string // team which the user belongs to
}

// WithRequest attaches a user to the given request.
func (u *User) WithRequest(req *http.Request) *http.Request {
	return req.WithContext(context.WithValue(req.Context(), UserContextKey, u))
}

// Strings implements the fmt.Stringer interface.
func (u *User) String() string {
	return u.Team + "/" + u.Username
}

// Session represents a user session.
type Session struct {
	ClientID string // an ID of an authenticated session.
	User     *User  // authenticated user
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

// WriteTo writes the s session to the given requeest.
func (s *Session) WriteTo(req *http.Request) {
	req.Header.Set("Authorization", "Bearer "+s.ClientID)
}

// ReadFrom initializes the s session by reading it from
// the given request.
//
// If no session can be read from req, the method is a nop.
func (s *Session) ReadFrom(req *http.Request) {
	if auth := req.Header.Get("Authorization"); strings.HasPrefix(auth, "Bearer ") {
		s.ClientID = auth[len("Bearer "):]
	}
}

// Match tests whether the other session matches the s one.
//
// Since ClientID is typically auto-generated, we match all the other fields.
func (s *Session) Match(other *Session) error {
	if s.User.Username != other.User.Username {
		return fmt.Errorf("username is  %q, the other one is %q", s.User.Username, other.User.Username)
	}

	if s.User.Team != other.User.Team {
		return fmt.Errorf("team is  %q, the other one is %q", s.User.Team, other.User.Team)
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
	// User represents a user, which we are building
	// authorisation for.
	User *User

	// Refresh requests to refresh a session when true.
	Refresh bool

	// Request is a copy of the request, which
	// we're building authorisation for.
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
	http.RoundTripper                // a transport to use; optional, by default http.DefaultClient.Transport
	AuthFunc          AuthFunc       // clientID authorisation to use; required
	UserFunc          UserFunc       // used to get a user from request to authenticate for; by default looked up with UserContextKey
	Host              string         // original Host name, overwrites req.Host; optional
	RetryNum          int            // number of retries in case of temporary failures; optional, by default 3
	Log               logging.Logger // logger to use
	Debug             bool           // whether to dump HTTP request/response

	// request mapping implementation stolen from:
	//
	//   https://github.com/golang/oauth2/blob/master/transport.go
	//
	mu     sync.Mutex                      // guards modReq
	modReq map[*http.Request]*http.Request // original -> modified
}

var _ httpTransport = (*Transport)(nil)

// NewSingleUser returns a HTTP transport that authenticates all
// requests for the given user.
//
// This is useful for api clients that give no control over HTTP requests,
// like the swagger-generated ones (remote.api).
func (t *Transport) NewSingleUser(u *User) http.RoundTripper {
	return &Transport{
		RoundTripper: t.RoundTripper,
		AuthFunc:     t.AuthFunc,
		UserFunc:     func(*http.Request) *User { return u },
		Host:         t.Host,
		RetryNum:     t.RetryNum,
		Log:          t.Log,
		Debug:        t.Debug,
	}
}

// RoundTrip implements the http.RoundTripper interface.
func (t *Transport) RoundTrip(req *http.Request) (*http.Response, error) {
	type body interface {
		io.ReadSeeker
		io.Closer
	}

	user := t.user(req)
	if user == nil {
		return t.roundTripper().RoundTrip(req)
	}

	reqCopy := copyRequest(req) // per RoundTripper contract
	t.setModReq(req, reqCopy)

	var save body

	switch b := reqCopy.Body.(type) {
	case nil:
	case body:
		save = b
	default:
		p, err := ioutil.ReadAll(io.LimitReader(reqCopy.Body, maxBodyLen))
		if err != nil {
			return nil, err // non-retryable
		}

		save = nopCloser{bytes.NewReader(p)}
	}

	var refresh bool
	var lastErr error
	var session *Session

	for attempts := t.retryNum(); attempts >= 0; attempts-- {
		if reqCopy.Body != nil {
			rewind := save

			if b, ok := reqCopy.Body.(body); ok {
				rewind = b
			}

			if _, err := rewind.Seek(0, io.SeekStart); err != nil {
				return nil, err // non-retryable
			}

			reqCopy.Body = rewind
		}

		opts := &AuthOptions{
			User:    user,
			Refresh: refresh,
			Request: reqCopy,
			Error:   lastErr,
		}

		s, err := t.AuthFunc(opts)

		t.log().Debug("AuthFunc(%+v): session=%+v, error=%v", opts, s, err)

		if err != nil {
			return nil, err // non-retryable
		}

		if err := s.Valid(); err != nil {
			return nil, err // non-retryable
		}

		session = s
		refresh = false

		session.WriteTo(reqCopy)

		if t.Host != "" {
			reqCopy.Host = t.Host
		}

		if t.Debug {
			p, err := httputil.DumpRequestOut(reqCopy, true)
			t.log().Debug("[request] %s (err=%v)", p, err)
		}

		resp, err := t.roundTripper().RoundTrip(reqCopy)

		if t.Debug && err == nil {
			p, err := httputil.DumpResponse(resp, true)
			t.log().Debug("[response] %s (err=%v)", p, err)
		}

		if e, ok := err.(net.Error); ok && (e.Temporary() || e.Timeout()) {
			lastErr = err
			continue // retry
		}

		if err != nil {
			t.setModReq(req, nil)
			return nil, err // non-retryable
		}

		switch resp.StatusCode {
		case http.StatusInternalServerError:
			// TODO(rjeczalik): remove, this is a temporary workaround
			// for remote.api, that return 500 when session could not
			// be validated.
			fallthrough
		case http.StatusUnauthorized:
			resp.Body.Close()
			lastErr = errors.New(http.StatusText(resp.StatusCode))
			refresh = true
			continue // retry and force new session
		}

		resp.Body = &onEOFReader{
			rc: resp.Body,
			fn: func() { t.setModReq(req, nil) },
		}

		return resp, nil
	}

	t.setModReq(req, nil)

	return nil, fmt.Errorf("api: error sending request: %v", lastErr)
}

func (t *Transport) CancelRequest(req *http.Request) {
	if rc, ok := t.roundTripper().(httpRequestCanceler); ok {
		t.mu.Lock()
		modReq := t.modReq[req]
		delete(t.modReq, req)
		t.mu.Unlock()

		rc.CancelRequest(modReq)
	}
}

func (t *Transport) CloseIdleConnections() {
	if icl, ok := t.roundTripper().(httpIdleConnectionsCloser); ok {
		icl.CloseIdleConnections()
	}
}

func (t *Transport) user(req *http.Request) *User {
	if t.UserFunc != nil {
		return t.UserFunc(req)
	}
	user, _ := req.Context().Value(UserContextKey).(*User)
	return user
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

func (t *Transport) log() logging.Logger {
	if t.Log != nil {
		return t.Log
	}
	return defaultLog
}

func (t *Transport) setModReq(orig, mod *http.Request) {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.modReq == nil {
		t.modReq = make(map[*http.Request]*http.Request)
	}
	if mod == nil {
		delete(t.modReq, orig)
	} else {
		t.modReq[orig] = mod
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

type onEOFReader struct {
	rc io.ReadCloser
	fn func()
}

func (r *onEOFReader) Read(p []byte) (n int, err error) {
	n, err = r.rc.Read(p)
	if err == io.EOF {
		r.runFunc()
	}
	return
}

func (r *onEOFReader) Close() error {
	err := r.rc.Close()
	r.runFunc()
	return err
}

func (r *onEOFReader) runFunc() {
	if fn := r.fn; fn != nil {
		fn()
		r.fn = nil
	}
}
