package provider_test

import (
	"koding/kites/kloud/stack/provider"
	"reflect"

	"testing"
)

func TestVariables(t *testing.T) {
	const blank = "***"

	cases := map[string]struct {
		s    string
		vars []provider.Variable
		want string
	}{
		"single variable": {
			"${var.abc}",
			[]provider.Variable{{
				Name: "abc",
				From: 0,
				To:   10,
			}},
			"***",
		},
		"single variable with whitespace": {
			"${ var.abc  }",
			[]provider.Variable{{
				Name: "abc",
				From: 0,
				To:   13,
			}},
			"***",
		},
		"multiple variables": {
			"${var.abc}${var.def}foo${var.ghi}",
			[]provider.Variable{{
				Name: "abc",
				From: 0,
				To:   10,
			}, {
				Name: "def",
				From: 10,
				To:   20,
			}, {
				Name: "ghi",
				From: 23,
				To:   33,
			}},
			"******foo***",
		},
		"multiple variables with whitespace": {
			"bar${var.abc  }${   var.def }foo${ var.ghi }foo",
			[]provider.Variable{{
				Name: "abc",
				From: 3,
				To:   15,
			}, {
				Name: "def",
				From: 15,
				To:   29,
			}, {
				Name: "ghi",
				From: 32,
				To:   44,
			}},
			"bar******foo***foo",
		},
	}

	for name, cas := range cases {
		// capture range variable here
		cas := cas
		t.Run(name, func(t *testing.T) {
			t.Parallel()
			vars := provider.ReadVariables(cas.s)

			if !reflect.DeepEqual(vars, cas.vars) {
				t.Fatalf("got %+v, want %+v", vars, cas.vars)
			}

			got := provider.ReplaceVariables(cas.s, cas.vars, blank)

			if got != cas.want {
				t.Fatalf("got %q, want %q", got, cas.want)
			}
		})
	}
}

func TestEscapeDeadVariables(t *testing.T) {
	cases := map[string]struct {
		userdata string
		want     string
	}{
		"simple": {
			"# ${var.something}\n",
			"# $${var.something}\n",
		},
		"multiple in single line": {
			"# ${var.one}${var.two}   ${var.three}\n",
			"# $${var.one}$${var.two}   $${var.three}\n",
		},
		"multiple in multiple lines": {
			"# ${var.one}\n#${var.two}\n   #    ${var.three}\n",
			"# $${var.one}\n#$${var.two}\n   #    $${var.three}\n",
		},
		"multiple in multiple lines without eofNL": {
			"# ${var.one}\n#${var.two}\n   #    ${var.three}",
			"# $${var.one}\n#$${var.two}\n   #    $${var.three}",
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			got := provider.EscapeDeadVariables(cas.userdata)

			if got != cas.want {
				t.Fatalf("got %q, want %q", got, cas.want)
			}
		})
	}
}
