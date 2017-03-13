package os_test

import (
	"reflect"
	"testing"

	"koding/klient/os"
)

func TestEnviron(t *testing.T) {
	cases := map[string]struct {
		s    string
		m, o os.Environ
		e    []string
	}{
		"single env": {
			"a=b",
			os.Environ{"a": "b"},
			nil,
			[]string{"a=b"},
		},
		"single env dangling comma": {
			"a=b,",
			os.Environ{"a": "b"},
			nil,
			[]string{"a=b"},
		},
		"multiple envs": {
			"a=b,,c=d,",
			os.Environ{"a": "b", "c": "d"},
			nil,
			[]string{"a=b", "c=d"},
		},
		"multiple envs with override": {
			",a=b,c=d,,e=f",
			os.Environ{"a": "b", "c": "d", "e": "f"},
			os.Environ{"g": "h", "c": "c"},
			[]string{"a=b", "c=c", "e=f", "g=h"},
		},
		"multiple envs with override and empty value": {
			",key=,env=foobar,,bar=foo,home=/home/rjeczalik",
			os.Environ{"key": "", "env": "foobar", "bar": "foo", "home": "/home/rjeczalik"},
			os.Environ{"home": "", "key": "home"},
			[]string{"bar=foo", "env=foobar", "home=", "key=home"},
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			m := os.ParseEnviron(cas.s)

			if !reflect.DeepEqual(m, cas.m) {
				t.Fatalf("got %+v, want %+v", m, cas.m)
			}

			if err := m.Match(cas.m); err != nil {
				t.Fatalf("Match()=%s", err)
			}

			if err := cas.m.Match(m); err != nil {
				t.Fatalf("Match()=%s", err)
			}

			e := m.Encode(cas.o)

			if !reflect.DeepEqual(e, cas.e) {
				t.Fatalf("got %v, want %v", e, cas.e)
			}
		})
	}
}
