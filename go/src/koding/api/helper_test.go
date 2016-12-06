package api_test

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"
	"sync"

	"koding/api"
	"koding/kites/kloud/utils"
)

type FakeAuth struct {
	Sessions map[string]*api.Session

	mu sync.RWMutex
}

func NewFakeAuth() *FakeAuth {
	return &FakeAuth{
		Sessions: make(map[string]*api.Session),
	}
}

func (fa *FakeAuth) Auth(opts *api.AuthOptions) (*api.Session, error) {
	fa.mu.Lock()
	defer fa.mu.Unlock()

	session, ok := fa.Sessions[opts.Session.Key()]
	if !ok || opts.Refresh {
		session = &api.Session{
			ClientID: utils.RandString(12),
			Username: opts.Session.Username,
			Team:     opts.Session.Team,
		}

		fa.Sessions[opts.Session.Key()] = session
	}

	return session, nil
}

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

	p, err := ioutil.ReadAll(r.Body)
	api.Log.Info("FakeAuth.GetSession: read body: p=%q, err=%v", p, err)

	if session == nil {
		w.WriteHeader(http.StatusUnauthorized)
	} else {
		json.NewEncoder(w).Encode(session)
	}
}

type AuthRecorder struct {
	Options  []*api.AuthOptions
	AuthFunc api.AuthFunc
}

func (ar *AuthRecorder) Auth(opts *api.AuthOptions) (*api.Session, error) {
	sessionCopy := *opts.Session
	optsCopy := *opts
	optsCopy.Session = &sessionCopy
	optsCopy.Request = nil

	ar.Options = append(ar.Options, &optsCopy)

	return ar.AuthFunc(opts)
}

func (ar *AuthRecorder) Reset() {
	ar.Options = ar.Options[:0]
}

type Trx struct {
	Type    string // "set", "get" or "delete"
	Session *api.Session
}

type TrxStorage struct {
	Trxs []Trx

	mu sync.Mutex
}

var _ api.Storage = (*TrxStorage)(nil)

func (trx *TrxStorage) Get(s *api.Session) (*api.Session, error) {
	trx.mu.Lock()
	trx.Trxs = append(trx.Trxs, Trx{Type: "get", Session: s})
	trxS, ok := trx.build()[s.Key()]
	trx.mu.Unlock()

	if !ok {
		return nil, api.ErrSessionNotFound
	}

	return trxS, nil
}

func (trx *TrxStorage) Set(s *api.Session) error {
	trx.mu.Lock()
	trx.Trxs = append(trx.Trxs, Trx{Type: "set", Session: s})
	trx.mu.Unlock()
	return nil
}

func (trx *TrxStorage) Delete(s *api.Session) error {
	trx.mu.Lock()
	trx.Trxs = append(trx.Trxs, Trx{Type: "delete", Session: s})
	trx.mu.Unlock()
	return nil
}

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

func (trx *TrxStorage) Build() map[string]*api.Session {
	trx.mu.Lock()
	defer trx.mu.Unlock()

	return trx.build()
}

func (trx *TrxStorage) Slice(i int) *TrxStorage {
	trx.mu.Lock()
	defer trx.mu.Unlock()

	slicedTrx := &TrxStorage{
		Trxs: make([]Trx, len(trx.Trxs)-i),
	}

	copy(slicedTrx.Trxs, trx.Trxs[i:])

	return slicedTrx
}

func (trx *TrxStorage) build() map[string]*api.Session {
	m := make(map[string]*api.Session)

	for _, trx := range trx.Trxs {
		switch trx.Type {
		case "get":
			// read-only op, ignore
		case "set":
			m[trx.Session.Key()] = trx.Session
		case "delete":
			delete(m, trx.Session.Key())
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

type FakeTransport struct {
	http.RoundTripper
}

var _ api.HTTPTransport = (*FakeTransport)(nil)

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

func (ft FakeTransport) CancelRequest(req *http.Request) {
	if rc, ok := ft.RoundTripper.(api.HTTPRequestCanceler); ok {
		rc.CancelRequest(req)
	}
}

func (ft FakeTransport) CloseIdleConnections() {
	if icl, ok := ft.RoundTripper.(api.HTTPIdleConnectionsCloser); ok {
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

func WithErrors(req *http.Request, errs ...error) *http.Request {
	return req.WithContext(context.WithValue(req.Context(), ErrorContextKey, &errs))
}

func WithResponses(req *http.Request, resps ...*http.Response) *http.Request {
	return req.WithContext(context.WithValue(req.Context(), ResponseContextKey, &resps))
}

func WithResponseCodes(req *http.Request, codes ...int) *http.Request {
	resps := make([]*http.Response, len(codes))

	for i, code := range codes {
		resps[i] = &http.Response{
			StatusCode: code,
		}
	}

	return WithResponses(req, resps...)
}
