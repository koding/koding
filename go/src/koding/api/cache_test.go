package api_test

import (
	"reflect"
	"strconv"
	"sync"
	"testing"

	"koding/api"
	"koding/kites/kloud/utils"
)

func TestSessionCache(t *testing.T) {
	var storage TrxStorage
	var auth = NewFakeAuth()

	users := []*api.Session{
		{Username: "user1", Team: "foobar"},
		{Username: "user2", Team: "foobar"},
		{Username: "user3", Team: "foobar"},
		{Username: "user", Team: "team"},
	}

	cases := []struct {
		name string
		opts *api.AuthOptions // client
		trxs []Trx            // underlying cache operations
	}{{
		"new user1",
		&api.AuthOptions{
			Session: users[0],
		},
		[]Trx{
			{Type: "get", Session: users[0]},
			{Type: "set", Session: users[0]},
		},
	}, {
		"already cached user",
		&api.AuthOptions{
			Session: users[0],
		},
		[]Trx{
			{Type: "get", Session: users[0]},
		},
	}, {
		"nop on valid session",
		&api.AuthOptions{
			Session: &api.Session{
				ClientID: utils.RandString(12),
				Username: users[0].Username,
				Team:     users[0].Team,
			},
		},
		nil,
	}, {
		"invalide session of a cached user",
		&api.AuthOptions{
			Session: users[0],
			Refresh: true,
		},
		[]Trx{
			{Type: "delete", Session: users[0]},
			{Type: "set", Session: users[0]},
		},
	}, {
		"new user2",
		&api.AuthOptions{
			Session: users[1],
		},
		[]Trx{
			{Type: "get", Session: users[1]},
			{Type: "set", Session: users[1]},
		},
	}, {
		"new user3",
		&api.AuthOptions{
			Session: users[2],
		},
		[]Trx{
			{Type: "get", Session: users[2]},
			{Type: "set", Session: users[2]},
		},
	}, {
		"new user",
		&api.AuthOptions{
			Session: users[3],
		},
		[]Trx{
			{Type: "get", Session: users[3]},
			{Type: "set", Session: users[3]},
		},
	}}

	allKeys := make(map[string]struct{}, len(cases))
	for _, cas := range cases {
		allKeys[cas.opts.Session.Key()] = struct{}{}
	}

	cache := api.NewCache(auth.Auth)
	cache.Storage = &storage

	for _, cas := range cases {
		t.Run(cas.name, func(t *testing.T) {
			trxID := len(storage.Trxs)

			_, err := cache.Auth(cas.opts)
			if err != nil {
				t.Fatalf("Auth()=%s", err)
			}

			if err := storage.Slice(trxID).Match(cas.trxs); err != nil {
				t.Fatalf("Match()=%s", err)
			}
		})
	}

	if sessions := storage.Build(); !reflect.DeepEqual(sessions, auth.Sessions) {
		t.Fatalf("got %+v, want %+v", sessions, auth.Sessions)
	}

	if len(auth.Sessions) != len(allKeys) {
		t.Fatalf("want len(auth)=%d == len(allKeys)=%d", len(auth.Sessions), len(allKeys))
	}

	for key := range allKeys {
		if _, ok := auth.Sessions[key]; !ok {
			t.Fatalf("key %q not found in auth", key)
		}
	}
}

func TestSessionCacheParallel(t *testing.T) {
	var storage TrxStorage
	var auth = NewFakeAuth()

	cache := api.NewCache(auth.Auth)
	cache.Storage = &storage

	const ConcurrentAuths = 10

	var wg sync.WaitGroup
	wg.Add(ConcurrentAuths)
	for i := 0; i < ConcurrentAuths; i++ {
		go func(i int) {
			defer wg.Done()
			cache.Auth(&api.AuthOptions{
				Session: &api.Session{
					Username: "user" + strconv.Itoa(i),
					Team:     "foobar" + strconv.Itoa(i),
				},
			})
		}(i)
	}

	wg.Wait()

	if sessions := storage.Build(); !reflect.DeepEqual(sessions, auth.Sessions) {
		t.Fatalf("got %+v, want %+v", sessions, auth.Sessions)
	}

	if len(auth.Sessions) != ConcurrentAuths {
		t.Fatalf("want len(auth)=%d; got: %d", ConcurrentAuths, len(auth.Sessions))
	}
}
