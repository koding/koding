package config

import (
	"fmt"
	"net/url"
	"reflect"
	"testing"

	"koding/tools/utils"
)

func TestReplaceEnv(t *testing.T) {
	tests := []struct {
		Environment  string
		ProvEnv      string
		ProvVariable string
		Exp          string
		ExpNoManaged string
	}{
		{
			// 0 //
			Environment:  "sandbox",
			ProvEnv:      "sandbox",
			ProvVariable: "https://koding.com/sandbox/version.txt",
			Exp:          "https://koding.com/development/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
		{
			// 1 //
			Environment:  "production",
			ProvEnv:      "managed",
			ProvVariable: "https://koding.com/production/version.txt",
			Exp:          "https://koding.com/managed/version.txt",
			ExpNoManaged: "https://koding.com/production/version.txt",
		},
		{
			// 2 //
			Environment:  "production",
			ProvEnv:      "devmanaged",
			ProvVariable: "https://koding.com/production/version.txt",
			Exp:          "https://koding.com/devmanaged/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
		{
			// 3 //
			Environment:  "default",
			ProvEnv:      "sandbox",
			ProvVariable: "https://koding.com/default/version.txt",
			Exp:          "https://koding.com/development/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
		{
			// 4 //
			Environment:  "production",
			ProvEnv:      "production",
			ProvVariable: "https://koding.com/production/version.txt",
			Exp:          "https://koding.com/production/version.txt",
			ExpNoManaged: "https://koding.com/production/version.txt",
		},
		{
			// 5 //
			Environment:  "development",
			ProvEnv:      "devmanaged",
			ProvVariable: "https://koding.com/development/version.txt",
			Exp:          "https://koding.com/devmanaged/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
		{
			// 6 //
			Environment:  "default",
			ProvEnv:      "devmanaged",
			ProvVariable: "https://koding.com/default/version.txt",
			Exp:          "https://koding.com/devmanaged/version.txt",
			ExpNoManaged: "https://koding.com/development/version.txt",
		},
	}

	for i, test := range tests {
		t.Run(fmt.Sprintf("test_no_%d", i), func(t *testing.T) {
			provVariable := NewEndpoint(test.ProvVariable)
			exp := NewEndpoint(test.Exp)
			expNoManaged := NewEndpoint(test.ExpNoManaged)

			if e := ReplaceCustomEnv(provVariable, test.Environment, test.ProvEnv); !e.Equal(exp) {
				t.Fatalf("want %s; got %s", test.Exp, e)
			}

			if e := ReplaceCustomEnv(provVariable, test.Environment, RmManaged(test.ProvEnv)); !e.Equal(expNoManaged) {
				t.Fatalf("want %s; got %s", test.Exp, e)
			}
		})
	}
}

func TestEndpointEqual(t *testing.T) {
	good := mustURL("http://127.0.0.1:56789/kite")
	bad := mustURL("http://127.0.0.1")

	cases := map[string]struct {
		lhs *Endpoint
		rhs *Endpoint
		ok  bool
	}{
		"empty endpoints": {
			&Endpoint{},
			&Endpoint{},
			true,
		},
		"public private match": {
			&Endpoint{
				Public:  good,
				Private: good,
			},
			&Endpoint{
				Public:  good,
				Private: good,
			},
			true,
		},
		"public match": {
			&Endpoint{
				Public: good,
			},
			&Endpoint{
				Public: good,
			},
			true,
		},
		"private match": {
			&Endpoint{
				Private: good,
			},
			&Endpoint{
				Private: good,
			},
			true,
		},
		"public private no match": {
			&Endpoint{
				Public:  good,
				Private: bad,
			},
			&Endpoint{
				Public:  bad,
				Private: good,
			},
			false,
		},
		"public no match": {
			&Endpoint{
				Public: good,
			},
			&Endpoint{
				Public: bad,
			},
			false,
		},
		"private no match": {
			&Endpoint{
				Private: good,
			},
			&Endpoint{
				Private: bad,
			},
			false,
		},
		"public no match private match": {
			&Endpoint{
				Public:  good,
				Private: good,
			},
			&Endpoint{
				Public:  bad,
				Private: good,
			},
			false,
		},
		"private no match public match": {
			&Endpoint{
				Public:  good,
				Private: good,
			},
			&Endpoint{
				Public:  bad,
				Private: good,
			},
			false,
		},
	}

	for name, cas := range cases {
		// capture range variable here
		cas := cas
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			if ok := cas.lhs.Equal(cas.rhs); ok != cas.ok {
				t.Fatalf("got %t, want %t", ok, cas.ok)
			}
		})
	}
}

func TestURLCopy(t *testing.T) {
	cases := map[string]*URL{
		"nil url":            nil,
		"nil underlying url": {URL: nil},
		"simple url":         {URL: &url.URL{Scheme: "http", Host: "example.com"}},
		"url with user":      {URL: &url.URL{Scheme: "http", Host: "example.com", User: url.UserPassword("user", "pass")}},
	}

	for name, u := range cases {
		// capture range variable here
		u := u
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			uCopy := u.Copy()

			if u.IsNil() {
				if uCopy != nil {
					t.Errorf("want uCopy to be nil; got %#v", uCopy)
				}

				return
			}

			modifyURL(uCopy)

			if reflect.DeepEqual(uCopy, u) {
				t.Errorf("want %#v != %#v", uCopy, u)
			}
		})
	}
}

func modifyURL(u *URL) {
	if u.IsNil() {
		return
	}

	u.URL.Host = utils.RandomString()

	if u.URL.User != nil {
		u.URL.User = url.UserPassword(utils.RandomString(), "")
	}
}

func TestEndpointCopy(t *testing.T) {
	url := &URL{URL: &url.URL{Scheme: "http", Host: "example.com", User: url.UserPassword("user", "pass")}}

	cases := map[string]*Endpoint{
		"nil endpoint":          nil,
		"nil underlying urls":   {Private: nil, Public: nil},
		"private-only endpoint": {Private: url},
		"public-only endpoint":  {Public: url},
		"endpoint":              {Private: url, Public: url},
	}

	for name, e := range cases {
		// capture range variable here
		e := e
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			eCopy := e.Copy()

			if e.IsNil() {
				if eCopy != nil {
					t.Errorf("want eCopy to be nil; got %#v", eCopy)
				}

				return
			}

			modifyEndpoint(eCopy)

			if reflect.DeepEqual(eCopy, e) {
				t.Errorf("want %#v != %#v", eCopy, e)
			}
		})
	}
}

func modifyEndpoint(e *Endpoint) {
	if e.IsNil() {
		return
	}

	if !e.Public.IsNil() {
		modifyURL(e.Public)
	}

	if !e.Private.IsNil() {
		modifyURL(e.Private)
	}
}
