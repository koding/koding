package socialapi_test

import (
	"encoding/json"
	"log"
	"net/http"
	"strings"
	"testing"

	"koding/kites/tunnelproxy/discover/discovertest"
	"koding/socialapi"
)

func TestTransport(t *testing.T) {
	var storage TrxStorage
	var auth = NewFakeAuth()

	s, err := discovertest.NewServer(http.HandlerFunc(auth.GetSession))
	if err != nil {
		t.Fatalf("NewServer()=%s", err)
	}
	defer s.Close()

	cache := socialapi.NewCache(auth.Auth)
	cache.Storage = &storage

	users := []*socialapi.Session{
		{Username: "user1", Team: "foobar"},
		{Username: "user2", Team: "foobar"},
		{Username: "user3", Team: "foobar"},
		{Username: "user", Team: "team"},
	}

	cases := []struct {
		name  string
		sess  *socialapi.Session // client
		errs  []error            // fake errors for endpoint
		codes []int              // fake response codes for endpoint
		err   error              // final error from client
		trx   TrxStorage         // underlying cache operations
	}{{
		"new user1",
		users[0],
		nil, nil, nil,
		TrxStorage{
			{Type: "get", Session: users[0]},
			{Type: "set", Session: users[0]},
		},
	}}

	client := http.Client{
		Transport: &FakeTransport{
			Transport: &socialapi.Transport{
				AuthFunc: cache.Auth,
			},
		},
	}

	for _, cas := range cases {
		t.Run(cas.name, func(t *testing.T) {
			req, err := http.NewRequest("POST", s.URL, strings.NewReader(cas.name))
			if err != nil {
				t.Fatalf("NewRequest()=%s", err)
			}

			req = cas.sess.WithRequest(req)

			if len(cas.errs) != 0 {
				req = WithErrors(req, cas.errs...)
			}

			if len(cas.codes) != 0 {
				req = WithResponseCodes(req, cas.codes...)
			}

			resp, err := client.Do(req)
			if err != nil {
				t.Fatalf("Do()=%s", err)
			}

			if resp.StatusCode != http.StatusOK {
				t.Fatalf("got %q, want %q", http.StatusText(resp.StatusCode), http.StatusText(http.StatusOK))
			}

			var other socialapi.Session

			if err := json.NewDecoder(resp.Body).Decode(&other); err != nil {
				t.Fatalf("Decode()=%s", err)
			}

			if err := other.Valid(); err != nil {
				t.Fatalf("Valid()=%s", err)
			}

			if err := other.Match(cas.sess); err != nil {
				t.Fatalf("Match()=%s", err)
			}

			log.Printf("received session: %#v", &other)
		})
	}
}
