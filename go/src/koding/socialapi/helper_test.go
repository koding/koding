package socialapi_test

import (
	"context"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"sync"

	"koding/kites/kloud/utils"
	"koding/socialapi"
)

type FakeAuth struct {
	Sessions map[string]*socialapi.Session

	mu sync.RWMutex
}

func NewFakeAuth() *FakeAuth {
	return &FakeAuth{
		Sessions: make(map[string]*socialapi.Session),
	}
}

func (fa FakeAuth) Auth(opts *socialapi.AuthOptions) (*socialapi.Session, error) {
	fa.mu.Lock()
	defer fa.mu.Unlock()

	session, ok := fa.Sessions[opts.Session.Key()]
	if !ok || opts.Refresh {
		session = &socialapi.Session{
			ClientID: utils.RandString(12),
			Username: opts.Session.Username,
			Team:     opts.Session.Team,
		}
		fa.Sessions[opts.Session.Key()] = session
	}

	return session, nil
}

func (fa FakeAuth) GetSession(w http.ResponseWriter, r *http.Request) {
	var req socialapi.Session

	req.ReadFrom(r)

	var session *socialapi.Session

	fa.mu.RLock()
	for _, s := range fa.Sessions {
		if s.ClientID == req.ClientID {
			session = s
			break
		}
	}
	fa.mu.RUnlock()

	p, err := ioutil.ReadAll(r.Body)
	log.Printf("FakeAuth.GetSession: read body: p=%q, err=%v", p, err)

	if session == nil {
		w.WriteHeader(http.StatusUnauthorized)
	} else {
		json.NewEncoder(w).Encode(session)
	}
}

type AuthRecorder struct {
	Options  []*socialapi.AuthOptions
	AuthFunc socialapi.AuthFunc
}

func (ar *AuthRecorder) Auth(opts *socialapi.AuthOptions) (*socialapi.Session, error) {
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
	Session *socialapi.Session
}

type TrxStorage []Trx

var _ socialapi.Storage = (*TrxStorage)(nil)

func (trx *TrxStorage) Get(s *socialapi.Session) error {
	*trx = append(*trx, Trx{Type: "get", Session: s})

	trxS, ok := trx.Build()[s.Key()]
	if !ok {
		return socialapi.ErrSessionNotFound
	}

	*s = *trxS

	return nil
}

func (trx *TrxStorage) Set(s *socialapi.Session) error {
	*trx = append(*trx, Trx{Type: "set", Session: s})
	return nil
}

func (trx *TrxStorage) Delete(s *socialapi.Session) error {
	*trx = append(*trx, Trx{Type: "delete", Session: s})
	return nil
}

func (trx TrxStorage) Match(other TrxStorage) error {
	if len(trx) != len(other) {
		return fmt.Errorf("current storage has %d trxs, the other has %d", len(trx), len(other))
	}

	for i, trx := range trx {
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

func (trx TrxStorage) Build() map[string]*socialapi.Session {
	m := make(map[string]*socialapi.Session)

	for _, trx := range trx {
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

var _ socialapi.HTTPTransport = (*FakeTransport)(nil)

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
	if rc, ok := ft.RoundTripper.(socialapi.HTTPRequestCanceler); ok {
		rc.CancelRequest(req)
	}
}

func (ft FakeTransport) CloseIdleConnections() {
	if icl, ok := ft.RoundTripper.(socialapi.HTTPIdleConnectionsCloser); ok {
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
