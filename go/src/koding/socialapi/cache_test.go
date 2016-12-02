package socialapi_test

import (
	"reflect"
	"testing"

	"koding/kites/kloud/utils"
	"koding/socialapi"
)

func TestSessionCache(t *testing.T) {
	var storage TrxStorage
	var auth = make(FakeAuth)

	users := []*socialapi.Session{
		{Username: "user1", Team: "foobar"},
		{Username: "user2", Team: "foobar"},
		{Username: "user3", Team: "foobar"},
		{Username: "user", Team: "team"},
	}

	cases := []struct {
		name string
		opts *socialapi.AuthOptions
		trxs TrxStorage
	}{{
		"new user1",
		&socialapi.AuthOptions{
			Session: users[0],
		},
		TrxStorage{
			{Type: "get", Session: users[0]},
			{Type: "set", Session: users[0]},
		},
	}, {
		"already cached user",
		&socialapi.AuthOptions{
			Session: users[0],
		},
		TrxStorage{
			{Type: "get", Session: users[0]},
		},
	}, {
		"nop on valid session",
		&socialapi.AuthOptions{
			Session: &socialapi.Session{
				ClientID: utils.RandString(12),
				Username: users[0].Username,
				Team:     users[0].Team,
			},
		},
		nil,
	}, {
		"invalide session of a cached user",
		&socialapi.AuthOptions{
			Session: users[0],
			Refresh: true,
		},
		TrxStorage{
			{Type: "delete", Session: users[0]},
			{Type: "set", Session: users[0]},
		},
	}, {
		"new user2",
		&socialapi.AuthOptions{
			Session: users[1],
		},
		TrxStorage{
			{Type: "get", Session: users[1]},
			{Type: "set", Session: users[1]},
		},
	}, {
		"new user3",
		&socialapi.AuthOptions{
			Session: users[2],
		},
		TrxStorage{
			{Type: "get", Session: users[2]},
			{Type: "set", Session: users[2]},
		},
	}, {
		"new user",
		&socialapi.AuthOptions{
			Session: users[3],
		},
		TrxStorage{
			{Type: "get", Session: users[3]},
			{Type: "set", Session: users[3]},
		},
	}}

	allKeys := make(map[string]struct{}, len(cases))
	for _, cas := range cases {
		allKeys[cas.opts.Session.Key()] = struct{}{}
	}

	cache := socialapi.NewSessionCache(auth.Auth)
	cache.Storage = &storage

	for _, cas := range cases {
		t.Run(cas.name, func(t *testing.T) {
			trxID := len(storage)

			_, err := cache.Auth(cas.opts)
			if err != nil {
				t.Fatalf("Auth()=%s", err)
			}

			if err := storage[trxID:].Match(cas.trxs); err != nil {
				t.Fatalf("Match()=%s", err)
			}
		})
	}

	if storage := FakeAuth(storage.Build()); !reflect.DeepEqual(auth, storage) {
		t.Fatalf("got %+v, want %+v", auth, storage)
	}

	if len(auth) != len(allKeys) {
		t.Fatalf("want len(auth)=%d == len(allKeys)=%d", len(auth), len(allKeys))
	}

	for key := range allKeys {
		if _, ok := auth[key]; !ok {
			t.Fatalf("key %q not found in auth", key)
		}
	}
}
