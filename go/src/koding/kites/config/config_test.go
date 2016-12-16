package config

import (
	"fmt"
	"testing"
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

			// Temporarily replace buildin environment. This also means that you
			// should not run these test in parallel!
			var envcopy = environment
			environment = test.Environment
			defer func() {
				environment = envcopy
			}()

			if e := ReplaceEnv(provVariable, test.ProvEnv); !e.Equal(exp) {
				t.Fatalf("want string = %#v; got %#v", test.Exp, e)
			}

			if e := ReplaceEnv(provVariable, RmManaged(test.ProvEnv)); !e.Equal(expNoManaged) {
				t.Fatalf("want string = %#v; got %#v", test.Exp, e)
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
		t.Run(name, func(t *testing.T) {
			if ok := cas.lhs.Equal(cas.rhs); ok != cas.ok {
				t.Fatalf("got %t, want %t", ok, cas.ok)
			}
		})
	}
}
