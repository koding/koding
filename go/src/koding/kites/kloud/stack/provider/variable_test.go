package provider_test

import (
	"reflect"
	"testing"

	"koding/kites/kloud/stack/provider"
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
		"single expression variable": {
			"${base64encode(var.foo)}",
			[]provider.Variable{{
				Name:       "foo",
				From:       15,
				To:         22,
				Expression: true,
			}},
			"${base64encode(***)}",
		},
		"multiple expression variables": {
			"${func(var.foo123, var.bar-bar, var.baz_baz)}",
			[]provider.Variable{{
				Name:       "foo123",
				From:       7,
				To:         17,
				Expression: true,
			}, {
				Name:       "bar-bar",
				From:       19,
				To:         30,
				Expression: true,
			}, {
				Name:       "baz_baz",
				From:       32,
				To:         43,
				Expression: true,
			}},
			"${func(***, ***, ***)}",
		},
		"variables mix": {
			"abc ${func(var.foo, var.bar)} ${ var.baz}${var.qux} ${g(var.a, var.b)} def",
			[]provider.Variable{{
				Name:       "foo",
				From:       11,
				To:         18,
				Expression: true,
			}, {
				Name:       "bar",
				From:       20,
				To:         27,
				Expression: true,
			}, {
				Name: "baz",
				From: 30,
				To:   41,
			}, {
				Name: "qux",
				From: 41,
				To:   51,
			}, {
				Name:       "a",
				From:       56,
				To:         61,
				Expression: true,
			}, {
				Name:       "b",
				From:       63,
				To:         68,
				Expression: true,
			}},
			"abc ${func(***, ***)} ****** ${g(***, ***)} def",
		},
		"reset after partial match": {
			`${func(var.foo, "var", ".cde", var.bar)}`,
			[]provider.Variable{{
				Name:       "foo",
				From:       7,
				To:         14,
				Expression: true,
			}, {
				Name:       "bar",
				From:       31,
				To:         38,
				Expression: true,
			}},
			`${func(***, "var", ".cde", ***)}`,
		},
		"ternary operator expression": {
			`${terraform.env == "devel" ? var.foo : var.bar}`,
			[]provider.Variable{{
				Name:       "foo",
				From:       29,
				To:         36,
				Expression: true,
			}, {
				Name:       "bar",
				From:       39,
				To:         46,
				Expression: true,
			}},
			`${terraform.env == "devel" ? *** : ***}`,
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
