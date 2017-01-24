// Package apitest provides a number of mocks and other testing
// utilities, handy when writing tests for clients that
// communicate with socialworker / remote.api.
package apitest

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"sync"

	"koding/api"
	"koding/kites/kloud/utils"
	"koding/kites/tunnelproxy/discover/discovertest"
)

// HTTPTransport exports httpTransport for test purposes.
type HTTPTransport interface {
	http.RoundTripper
	HTTPRequestCanceler
	HTTPIdleConnectionsCloser
}

// HTTPRequestCanceler exports httpRequestCanceler for test purposes.
type HTTPRequestCanceler interface {
	CancelRequest(*http.Request)
}

// HTTPIdleConnectionsCloser exports httpIdleConnectionsCloser for
// tests purposes.
type HTTPIdleConnectionsCloser interface {
	CloseIdleConnections()
}

// FakeAuth is a mock which provides fake authentication server.
//
// It implements both client-facing interface  the Auth method -
// than can be used with clients' transports, and also a server-facing
// one - the GetSession method - which is a handler that can be
// used with http server.
type FakeAuth struct {
	Sessions map[string]*api.Session

	mu sync.RWMutex
}

var (
	_ http.Handler = http.HandlerFunc((&FakeAuth{}).GetSession)
	_ api.AuthFunc = api.AuthFunc((&FakeAuth{}).Auth)
)

// NewFakeAuth gives new FakeAuth value.
func NewFakeAuth() *FakeAuth {
	return &FakeAuth{
		Sessions: make(map[string]*api.Session),
	}
}

// Auth provides the api.AuthFunc function for use with clients' transports.
//
// It never fails and always returns a valid session.
func (fa *FakeAuth) Auth(opts *api.AuthOptions) (*api.Session, error) {
	fa.mu.Lock()
	defer fa.mu.Unlock()

	session, ok := fa.Sessions[opts.User.String()]
	if !ok || opts.Refresh {
		session = &api.Session{
			ClientID: utils.RandString(12),
			User: &api.User{
				Username: opts.User.Username,
				Team:     opts.User.Team,
			},
		}

		fa.Sessions[opts.User.String()] = session
	}

	return session, nil
}

// GetSession implements the http.Handler interface.
//
// The method responds with JSON-encoded api.Session value.
//
// GetSession validates the authentication - for every
// api.Session it reads from requests, the session must
// already exist in Sessions map. Otherwise handler
// responds with 401.
func (fa *FakeAuth) GetSession(w http.ResponseWriter, r *http.Request) {
	var req api.Session

	req.ReadFrom(r)

	var session *api.Session

	fa.mu.RLock()
	for _, s := range fa.Sessions {
		if s.ClientID == req.ClientID {
			session = s
			break
		}
	}
	fa.mu.RUnlock()

	if session == nil {
		w.WriteHeader(http.StatusUnauthorized)
	} else {
		json.NewEncoder(w).Encode(session)
	}
}

// AuthRecorder is a wrapper for api.AuthFunc that records each
// api.AuthOptions passed to the function upon invocation.
type AuthRecorder struct {
	Options  []*api.AuthOptions
	AuthFunc api.AuthFunc
}

// Auth provides api.AuthFunc function.
func (ar *AuthRecorder) Auth(opts *api.AuthOptions) (*api.Session, error) {
	userCopy := *opts.User
	optsCopy := *opts
	optsCopy.User = &userCopy
	optsCopy.Request = nil

	ar.Options = append(ar.Options, &optsCopy)

	return ar.AuthFunc(opts)
}

// Reset clears all recorder AuthOptions.
func (ar *AuthRecorder) Reset() {
	ar.Options = ar.Options[:0]
}

// Trx represents a single storage operation.
type Trx struct {
	Type    string // "set", "get" or "delete"
	Session *api.Session
}

// TrxStorage is an api.Storage implementation which records
// all storage operations, so it can be used to ensure
// a logic correctly uses underlying storage.
//
// Moreover TrxStorage is able to reconstruct the Session
// state an any point of time with Slice and Build methods.
type TrxStorage struct {
	Trxs []Trx

	mu sync.Mutex
}

var _ api.Storage = (*TrxStorage)(nil)

// Get implememnts the api.Storage interface.
//
// If session for requested user does not exist,
// api.ErrSessionNotFound is returned.
func (trx *TrxStorage) Get(u *api.User) (*api.Session, error) {
	trx.mu.Lock()
	trx.Trxs = append(trx.Trxs, Trx{Type: "get", Session: &api.Session{User: u}})
	trxS, ok := trx.build()[u.String()]
	trx.mu.Unlock()

	if !ok {
		return nil, api.ErrSessionNotFound
	}

	return trxS, nil
}

// Set implememnts the api.Storage interface.
//
// The is guaranteed to always return nil error.
func (trx *TrxStorage) Set(s *api.Session) error {
	trx.mu.Lock()
	trx.Trxs = append(trx.Trxs, Trx{Type: "set", Session: s})
	trx.mu.Unlock()
	return nil
}

// Delete implememnts the api.Storage interface.
//
// The is guaranteed to always return nil error.
func (trx *TrxStorage) Delete(s *api.Session) error {
	trx.mu.Lock()
	trx.Trxs = append(trx.Trxs, Trx{Type: "delete", Session: s})
	trx.mu.Unlock()
	return nil
}

// Match ensures all recorded storage operations match other ones.
//
// If they do not match, an non-nil error is returned explaining why.
func (trx *TrxStorage) Match(other []Trx) error {
	trx.mu.Lock()
	defer trx.mu.Unlock()

	if len(trx.Trxs) != len(other) {
		return fmt.Errorf("current storage has %d trxs, the other has %d", len(trx.Trxs), len(other))
	}

	for i, trx := range trx.Trxs {
		if trx.Type != other[i].Type {
			return fmt.Errorf("trx %d is of %q type, the other one is %q",
				i, trx.Type, other[i].Type)
		}

		if err := trx.Session.Match(other[i].Session); err != nil {
			return fmt.Errorf("trx %d: %s", i, err)
		}
	}

	return nil
}

// Build replies all recorded storage operations and applies them on
// a new session map - the returned map represents the state of the storage.
func (trx *TrxStorage) Build() map[string]*api.Session {
	trx.mu.Lock()
	defer trx.mu.Unlock()

	return trx.build()
}

// Slice skips first n records and creates a new TrxStorage
// from the rest of the records.
//
// The returned storage contains a copy of the elements.
func (trx *TrxStorage) Slice(n int) *TrxStorage {
	trx.mu.Lock()
	defer trx.mu.Unlock()

	slicedTrx := &TrxStorage{
		Trxs: make([]Trx, len(trx.Trxs)-n),
	}

	copy(slicedTrx.Trxs, trx.Trxs[n:])

	return slicedTrx
}

func (trx *TrxStorage) build() map[string]*api.Session {
	m := make(map[string]*api.Session)

	for _, trx := range trx.Trxs {
		switch trx.Type {
		case "get":
			// read-only op, ignore
		case "set":
			m[trx.Session.User.String()] = trx.Session
		case "delete":
			delete(m, trx.Session.User.String())
		}
	}

	return m
}

type contextKey struct {
	name string
}

var (
	ErrorContextKey    = &contextKey{"fake-error"}
	ResponseContextKey = &contextKey{"fake-response"}
)

// FakeTransport is a wrapper for http.RoundTripper that fakes
// transport errors and http response codes.
type FakeTransport struct {
	http.RoundTripper
}

var _ HTTPTransport = (*FakeTransport)(nil)

// RoundTrip implements the http.RoundTripper interface.
//
// If a Context that comes with the request contains ErrorContextKey,
// the value associated with that key is used to fake transport error.
//
// If a Context that comes with the request contains ResponseContextKey,
// the value associated with that key is used to fake http response code.
func (ft FakeTransport) RoundTrip(req *http.Request) (resp *http.Response, err error) {
	errs, ok := req.Context().Value(ErrorContextKey).(*[]error)
	if ok && len(*errs) != 0 {
		err, *errs = (*errs)[0], (*errs)[1:]
		return nil, err
	}

	resps, ok := req.Context().Value(ResponseContextKey).(*[]*http.Response)
	if ok && len(*resps) != 0 {
		resp, *resps = (*resps)[0], (*resps)[1:]
		return resp, nil
	}

	return ft.roundTripper().RoundTrip(req)
}

// CancelRequest calls CancelRequest on the underlying transport,
// if the transport does support it.
func (ft FakeTransport) CancelRequest(req *http.Request) {
	if rc, ok := ft.RoundTripper.(HTTPRequestCanceler); ok {
		rc.CancelRequest(req)
	}
}

// CloseIdleConnections calls CloseIdleConnections on the underlying transport,
// if the transport does support it.
func (ft FakeTransport) CloseIdleConnections() {
	if icl, ok := ft.RoundTripper.(HTTPIdleConnectionsCloser); ok {
		icl.CloseIdleConnections()
	}
}

func (ft FakeTransport) roundTripper() http.RoundTripper {
	if ft.RoundTripper != nil {
		return ft.RoundTripper
	}

	if http.DefaultClient.Transport != nil {
		return http.DefaultClient.Transport
	}

	return http.DefaultTransport
}

// WithError associates the given errors with the request.
//
// If the request is served by a FakeTransport, the errors
// are going to be used to fake transport errors.
func WithErrors(req *http.Request, errs ...error) *http.Request {
	return req.WithContext(context.WithValue(req.Context(), ErrorContextKey, &errs))
}

// WithError associates the given responses with the request.
//
// If the request is served by a FakeTransport, the responses
// are going to be used to fake transport responses.
func WithResponses(req *http.Request, resps ...*http.Response) *http.Request {
	return req.WithContext(context.WithValue(req.Context(), ResponseContextKey, &resps))
}

// WithError associates the given response codes with the request.
//
// If the request is served by a FakeTransport, the codes
// are going to be used to fake transport response codes.
func WithResponseCodes(req *http.Request, codes ...int) *http.Request {
	resps := make([]*http.Response, len(codes))

	for i, code := range codes {
		resps[i] = &http.Response{
			Body:       ioutil.NopCloser(bytes.NewReader([]byte{})),
			StatusCode: code,
		}
	}

	return WithResponses(req, resps...)
}

// StubHandler implememts a http.Handler, that pops first
// element from the slice, JSON-encodes it and responds
// with 200 status code.
type StubHandler []interface{}

// ServeHTTP implements the http.Handler interface.
func (sh *StubHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	if len(*sh) == 0 {
		w.WriteHeader(http.StatusNoContent)
		return
	}

	var v interface{}
	v, *sh = (*sh)[0], (*sh)[1:]

	if v == nil {
		v = make(map[string]interface{}) // return empty object instead
	}

	w.Header().Set("Content-Type", "application/json")

	if err := json.NewEncoder(w).Encode(v); err != nil {
		panic("unexpected failure writing response: " + err.Error())
	}
}

// Serve starts a test server with the given handler.
//
// The function does not return until a listener, which is used
// by the server for accepting connections, is ready.
func Serve(h http.Handler) *httptest.Server {
	s, err := discovertest.NewServer(h)
	if err != nil {
		panic("unexpected error creating test server: " + err.Error())
	}
	return s
}
