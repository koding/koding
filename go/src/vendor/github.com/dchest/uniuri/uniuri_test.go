// Written in 2011-2014 by Dmitry Chestnykh
//
// The author(s) have dedicated all copyright and related and
// neighboring rights to this software to the public domain
// worldwide. Distributed without any warranty.
// http://creativecommons.org/publicdomain/zero/1.0/

package uniuri

import "testing"

func validateChars(t *testing.T, u string, chars []byte) {
	for _, c := range u {
		var present bool
		for _, a := range chars {
			if rune(a) == c {
				present = true
			}
		}
		if !present {
			t.Fatalf("chars not allowed in %q", u)
		}
	}
}

func TestNew(t *testing.T) {
	u := New()
	// Check length
	if len(u) != StdLen {
		t.Fatalf("wrong length: expected %d, got %d", StdLen, len(u))
	}
	// Check that only allowed characters are present
	validateChars(t, u, StdChars)

	// Generate 1000 uniuris and check that they are unique
	uris := make([]string, 1000)
	for i := range uris {
		uris[i] = New()
	}
	for i, u := range uris {
		for j, u2 := range uris {
			if i != j && u == u2 {
				t.Fatalf("not unique: %d:%q and %d:%q", i, u, j, u2)
			}
		}
	}
}

func TestNewLen(t *testing.T) {
	for i := 0; i < 100; i++ {
		u := NewLen(i)
		if len(u) != i {
			t.Fatalf("request length %d, got %d", i, len(u))
		}
	}
}

func TestNewLenChars(t *testing.T) {
	length := 10
	chars := []byte("01234567")
	u := NewLenChars(length, chars)

	// Check length
	if len(u) != length {
		t.Fatalf("wrong length: expected %d, got %d", StdLen, len(u))
	}
	// Check that only allowed characters are present
	validateChars(t, u, chars)

	// Check that two generated strings are different
	u2 := NewLenChars(length, chars)
	if u == u2 {
		t.Fatalf("not unique: %q and %q", u, u2)
	}
}

func TestNewLenCharsMaxLength(t *testing.T) {
	defer func() {
		if r := recover(); r == nil {
			t.Fatal("didn't panic")
		}
	}()
	chars := make([]byte, 257)
	NewLenChars(32, chars)
}

func TestBias(t *testing.T) {
	chars := []byte("abcdefghijklmnopqrstuvwxyz")
	slen := 100000
	s := NewLenChars(slen, chars)
	counts := make(map[rune]int)
	for _, b := range s {
		counts[b]++
	}
	avg := float64(slen) / float64(len(chars))
	for k, n := range counts {
		diff := float64(n) / avg
		if diff < 0.95 || diff > 1.05 {
			t.Errorf("Bias on '%c': expected average %f, got %d", k, avg, n)
		}
	}
}
