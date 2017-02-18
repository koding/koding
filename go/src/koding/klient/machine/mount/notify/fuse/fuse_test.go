package fuse_test

import (
	"bytes"
	"testing"

	"koding/klient/machine/mount/notify/fuse"
)

func TestTrimRightNull(t *testing.T) {
	cases := map[string]struct {
		p    []byte
		want []byte
	}{
		"no null": {
			[]byte("a string"),
			[]byte("a string"),
		},
		"null-terminated": {
			[]byte{'a', ' ', 's', 't', 'r', 'i', 'n', 'g', 0},
			[]byte("a string"),
		},
		"null-padded": {
			[]byte{'a', ' ', 's', 't', 'r', 'i', 'n', 'g', 0, 0, 0, 0, 0, 0},
			[]byte("a string"),
		},
		"null only": {
			[]byte{0},
			[]byte{},
		},
		"multiple null only": {
			[]byte{0, 0, 0, 0, 0, 0},
			[]byte{},
		},
	}

	for name, cas := range cases {
		t.Run(name, func(t *testing.T) {
			got := fuse.TrimRightNull(cas.p)

			if bytes.Compare(got, cas.want) != 0 {
				t.Fatalf("got %v, want %v", got, cas.want)
			}
		})
	}
}
