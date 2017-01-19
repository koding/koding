package api_test

import (
	"encoding/json"
	"net"
	"net/http"
	"strings"
	"testing"

	"koding/api"
	"koding/api/apitest"
	"koding/kites/tunnelproxy/discover/discovertest"
)

func TestTransport(t *testing.T) {
	var auth = apitest.NewFakeAuth()

	s, err := discovertest.NewServer(http.HandlerFunc(auth.GetSession))
	if err != nil {
		t.Fatalf("NewServer()=%s", err)
	}
	defer s.Close()

	cache := api.NewCache(auth.Auth)

	users := []*api.Session{
		{User: &api.User{Username: "user1", Team: "foobar"}},
		{User: &api.User{Username: "user2", Team: "foobar"}},
		{User: &api.User{Username: "user3", Team: "foobar"}},
		{User: &api.User{Username: "user", Team: "team"}},
	}

	cases := []struct {
		name  string
		sess  *api.Session // client
		errs  []error      // fake errors for endpoint
		codes []int        // fake response codes for endpoint
		err   error        // final error from client
	}{{
		"new user1",
		users[0],
		nil, nil, nil,
	}, {
		"cached user1",
		users[0],
		nil, nil, nil,
	}, {
		"new user2",
		users[1],
		nil, nil, nil,
	}, {
		"new user3 with an error",
		users[2],
		[]error{&net.DNSError{IsTemporary: true}}, nil, nil,
	}, {
		"cached user3 with an error and response codes",
		users[2],
		[]error{&net.DNSError{IsTemporary: true}}, []int{401, 401}, nil,
	}}

	rec := &apitest.AuthRecorder{
		AuthFunc: cache.Auth,
	}

	client := http.Client{
		Transport: &api.Transport{
			RoundTripper: &apitest.FakeTransport{},
			AuthFunc:     rec.Auth,
		},
	}

	for _, cas := range cases {
		t.Run(cas.name, func(t *testing.T) {
			rec.Reset()

			req, err := http.NewRequest("POST", s.URL, strings.NewReader(cas.name))
			if err != nil {
				t.Fatalf("NewRequest()=%s", err)
			}

			req = cas.sess.User.WithRequest(req)

			if len(cas.errs) != 0 {
				req = apitest.WithErrors(req, cas.errs...)
			}

			if len(cas.codes) != 0 {
				req = apitest.WithResponseCodes(req, cas.codes...)
			}

			resp, err := client.Do(req)
			if err != nil {
				t.Fatalf("Do()=%s", err)
			}

			if want, got := 1+len(cas.errs)+len(cas.codes), len(rec.Options); got != want {
				t.Fatalf("want %d, got %d: %+v", got, want, rec.Options)
			}

			if resp.StatusCode != http.StatusOK {
				t.Fatalf("got %q, want %q", http.StatusText(resp.StatusCode), http.StatusText(http.StatusOK))
			}

			var other api.Session

			if err := json.NewDecoder(resp.Body).Decode(&other); err != nil {
				t.Fatalf("Decode()=%s", err)
			}

			if err := other.Valid(); err != nil {
				t.Fatalf("Valid()=%s", err)
			}

			if err := other.Match(cas.sess); err != nil {
				t.Fatalf("Match()=%s", err)
			}

			api.Log.Info("received session: %#v", &other)
		})
	}
}
