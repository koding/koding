// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package slug

import "testing"

func TestSlug(t *testing.T) {
	tests := [][]string{
		{"", ""},
		{"-", ""},
		{"a**b", "a_b"},
		{"  a  ", "a"},
		{"_a__b_", "a_b"},
		{"L'école", "l_ecole"},
		{"99 bottles of beer", "99_bottles_of_beer"},
		{"abc世界def", "abc_def"},
		{"\x08lol", "lol"},
	}

	for _, test := range tests {
		if Clean(test[0]) != test[1] {
			t.Error(Clean(test[0]), "!=", test[1])
		}
	}
}

func TestSlug_WithCustomReplacement(t *testing.T) {
	original := Replacement
	defer func() { Replacement = original }()
	Replacement = 'X'

	if Clean("a b") != "aXb" {
		t.Error(Clean("a b"), "!= aXb")
	}
}
