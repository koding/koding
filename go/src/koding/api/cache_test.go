package api_test

import (
	"reflect"
	"strconv"
	"sync"
	"testing"

	"koding/api"
	"koding/api/apitest"
)

func TestSessionCache(t *testing.T) {
	var storage apitest.TrxStorage
	var auth = apitest.NewFakeAuth()

	users := []*api.Session{
		{User: &api.User{Username: "user1", Team: "foobar"}},
		{User: &api.User{Username: "user2", Team: "foobar"}},
		{User: &api.User{Username: "user3", Team: "foobar"}},
		{User: &api.User{Username: "user", Team: "team"}},
	}

	usernames := make(map[string]struct{}, len(users))
	for _, user := range users {
		usernames[user.User.String()] = struct{}{}
	}

	cases := []struct {
		name string
		opts *api.AuthOptions // client
		trxs []apitest.Trx    // underlying cache operations
	}{{
		"new user1",
		&api.AuthOptions{
			User: users[0].User,
		},
		[]apitest.Trx{
			{Type: "get", Session: users[0]},
			{Type: "set", Session: users[0]},
		},
	}, {
		"already cached user",
		&api.AuthOptions{
			User: users[0].User,
		},
		[]apitest.Trx{
			{Type: "get", Session: users[0]},
		},
	}, {
		"invalide session of a cached user",
		&api.AuthOptions{
			User:    users[0].User,
			Refresh: true,
		},
		[]apitest.Trx{
			{Type: "delete", Session: users[0]},
			{Type: "set", Session: users[0]},
		},
	}, {
		"new user2",
		&api.AuthOptions{
			User: users[1].User,
		},
		[]apitest.Trx{
			{Type: "get", Session: users[1]},
			{Type: "set", Session: users[1]},
		},
	}, {
		"new user3",
		&api.AuthOptions{
			User: users[2].User,
		},
		[]apitest.Trx{
			{Type: "get", Session: users[2]},
			{Type: "set", Session: users[2]},
		},
	}, {
		"new user",
		&api.AuthOptions{
			User: users[3].User,
		},
		[]apitest.Trx{
			{Type: "get", Session: users[3]},
			{Type: "set", Session: users[3]},
		},
	}}

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

	if len(auth.Sessions) != len(usernames) {
		t.Fatalf("want len(auth)=%d == len(allKeys)=%d", len(auth.Sessions), len(usernames))
	}

	for username := range usernames {
		if _, ok := auth.Sessions[username]; !ok {
			t.Fatalf("username %q not found in auth", username)
		}
	}
}

func TestSessionCacheParallel(t *testing.T) {
	var storage apitest.TrxStorage
	var auth = apitest.NewFakeAuth()

	cache := api.NewCache(auth.Auth)
	cache.Storage = &storage

	const ConcurrentAuths = 10

	var wg sync.WaitGroup
	wg.Add(ConcurrentAuths)
	for i := 0; i < ConcurrentAuths; i++ {
		go func(i int) {
			defer wg.Done()
			cache.Auth(&api.AuthOptions{
				User: &api.User{
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
