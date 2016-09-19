package logrotate_test

import (
	"io"
	"io/ioutil"
	"koding/logrotate"
	"strings"
	"testing"
)

var cases = map[string]int64{
	"foo":                    3,
	"foobar":                 6,
	"foo\r\nbar\r\n":         10,
	strings.Repeat("a", 128): 128,
}

func TestCountingReader(t *testing.T) {
	for s, want := range cases {
		var got int64

		r := &logrotate.CountingReader{
			RS: strings.NewReader(s),
			N:  &got,
		}

		_, err := io.Copy(ioutil.Discard, r)
		if err != nil {
			t.Fatalf("%s: Copy()=%s", s, err)
		}

		if got != want {
			t.Fatalf("%s: got %d, want %d", s, got, want)
		}
	}
}

func TestCountingWriter(t *testing.T) {
	for s, want := range cases {
		var got int64

		w := &logrotate.CountingWriter{
			W: ioutil.Discard,
			N: &got,
		}

		_, err := io.Copy(w, strings.NewReader(s))
		if err != nil {
			t.Fatalf("%s: Copy()=%s", s, err)
		}

		if got != want {
			t.Fatalf("%s: got %d, want %d", s, got, want)
		}
	}
}
