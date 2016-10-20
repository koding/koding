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
			// Temporarily replace buildin environment. This also means that you
			// should not run these test in parallel!
			var envcopy = environment
			environment = test.Environment
			defer func() {
				environment = envcopy
			}()

			if s := ReplaceEnv(test.ProvVariable, test.ProvEnv); s != test.Exp {
				t.Fatalf("want string = %#v; got %#v", test.Exp, s)
			}

			if s := ReplaceEnv(test.ProvVariable, RmManaged(test.ProvEnv)); s != test.ExpNoManaged {
				t.Fatalf("want string = %#v; got %#v", test.Exp, s)
			}
		})
	}
}
