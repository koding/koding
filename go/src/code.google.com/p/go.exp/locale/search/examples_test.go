// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package search_test

import (
	"code.google.com/p/go.exp/locale/search"
	"code.google.com/p/go.text/language"
	"fmt"
)

func ExampleSearch() {
	p := func(x ...interface{}) {
		fmt.Println(x...)
	}
	s := search.New(language.En)
	s.SetOptions(search.IgnoreCase | search.IgnoreDiacritics)

	p(s.MatchString("A", "a"))
	p(s.MatchString("ö", "o"))
	p(s.FindString("gruss", "Schöne Gruße"))
	p(s.CommonPrefixString("Lösung", "lost"))

	s = search.New(language.De)
	p(s.FindString("gruss", "Schöne Gruße"))

	// TODO:Output:
	// true
	// true
	// nil
	// Lös
	// [8 13]
}

func ExamplePattern() {
	s := search.New(language.De)
	pat := s.CompileString("gruss")
	fmt.Println(pat.FindString("Schöne Gruße"))
	fmt.Println(pat.FindLastString("Schöne Gruße"))
	// TODO:Output:
	// [8 13]
	// [8 13]
}
