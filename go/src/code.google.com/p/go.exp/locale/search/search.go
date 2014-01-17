// Copyright 2013 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

// Package search provides language-sensitive string search functionality.
package search

import (
	"code.google.com/p/go.text/collate/colltab"
	"code.google.com/p/go.text/language"
)

// An Option specifies a search-related feature.
type Option int

const (
	IgnoreCase       Option = 1 << iota // Case-insensitive search.
	IgnoreDiacritics                    // Ignore diacritics. ("ö" == "o").
	IgnoreWidth                         // Ignore full versus normal width.
	WholeWord                           // Only match at whole-word boundaries.
	Literal                             // Exact equivalence.

	Loose = IgnoreCase | IgnoreDiacritics | IgnoreWidth
)

// Search provides language-sensitive search functionality.
type Search struct {
	c colltab.Weigher
}

// New returns a new Search for the given language.
func New(l language.Tag) *Search {
	return nil
}

// NewFromWeigher returns a Search given a Weigher.
func NewFromWeigher(t colltab.Weigher) *Search {
	return nil
}

// SetOptions configures s to the options specified by mask.
func (s *Search) SetOptions(mask Option) error {
	return nil
}

// Match checks whether a and b are equivalent.
func (s *Search) Match(a, b []byte) bool {
	return false
}

// MatchString checks whether a and b are equivalent.
func (s *Search) MatchString(a, b string) bool {
	return false
}

// HasPrefix tests whether the byte slice str begins with prefix.
func (s *Search) HasPrefix(str, prefix []byte) bool {
	return false
}

// HasPrefixString tests whether the string str begins with prefix.
func (s *Search) HasPrefixString(str, prefix string) bool {
	return false
}

// HasSuffix tests whether the byte slice str ends with suffix.
func (s *Search) HasSufix(str, suffix []byte) bool {
	return false
}

// HasSuffixString tests whether the string str ends with suffix.
func (s *Search) HasSufixString(str, suffix string) bool {
	return false
}

// CommonPrefix returns a[:n], where n is the largest value that
// satisfies s.Match(a[:n], b).
func (s *Search) CommonPrefix(a, b []byte) []byte {
	return nil
}

// CommonPrefixString returns a[:n], where n is the largest value that
// satisfies s.Match(a[:n], b).
func (s *Search) CommonPrefixString(a, b string) string {
	return ""
}

// Find returns a two-element slice of integers defining the leftmost
// match in b of pat. A return value of nil indicates no match.
func (s *Search) Find(b, pat []byte) []int {
	return nil
}

// FindString returns a two-element slice of integers defining the leftmost
// match in str of pat. A return value of nil indicates no match.
func (s *Search) FindString(str, pat string) []int {
	return nil
}

// FindLast returns a two-element slice of integers defining the rightmost
// match in b of pat. A return value of nil indicates no match.
func (s *Search) FindLast(b, pat []byte) []int {
	return nil
}

// FindLastString returns a two-element slice of integers defining the rightmost
// match in str of pat. A return value of nil indicates no match.
func (s *Search) FindLastString(str, pat string) []int {
	return nil
}

// FindAll returns a slice of successive matches of pat in b, each represented
// by a two-element slice of integers. A return value of nil indicates no match.
func (s *Search) FindAll(b, pat []byte) [][]int {
	return nil
}

// FindAllString returns a slice of successive matches of pat in str, each represented
// by a two-element slice of integers. A return value of nil indicates no match.
func (s *Search) FindAllString(str, pat string) [][]int {
	return nil
}

// Pattern holds a preprocessed search pattern.  On repeated use of a search
// pattern, it will be more efficient to use Pattern than the direct methods.
type Pattern struct {
	s        *Search
	colelems []colltab.Elem
}

// Compile creates a Pattern from b that can be used to match against text.
func (s *Search) Compile(b []byte) *Pattern {
	return &Pattern{s, nil}
}

// CompileString creates a Pattern from b that can be used to match against text.
func (s *Search) CompileString(b string) *Pattern {
	return &Pattern{s, nil}
}

// Match checks whether b matches p.
func (p *Pattern) Match(b []byte) bool {
	return false
}

// MatchString checks whether b is equivalent to p.
func (p *Pattern) MatchString(b []byte) bool {
	return false
}

// CommonPrefix returns b[:n], where n is the largest value that
// satisfies p.Match(b[:n]).
func (p *Pattern) CommonPrefix(b []byte) []byte {
	return nil
}

// CommonPrefixString returns s[:n], where n is the largest value that
// satisfies p.Match(s[:n]).
func (p *Pattern) CommonPrefixString(s string) []byte {
	return nil
}

// HasPrefix tests whether the byte slice b begins with p.
func (p *Pattern) HasPrefix(b []byte) bool {
	return false
}

// HasPrefixString tests whether the string s begins with p.
func (p *Pattern) HasPrefixString(s string) bool {
	return false
}

// HasSuffix tests whether the byte slice b ends with p.
func (p *Pattern) HasSuffix(b []byte) bool {
	return false
}

// HasSuffixString tests whether the string s ends with p.
func (p *Pattern) HasSuffixString(s string) bool {
	return false
}

// Find returns a two-element slice of integers defining the leftmost
// match of p in b. A return value of nil indicates no match.
func (p *Pattern) Find(b []byte) []int {
	return nil
}

// FindString returns a two-element slice of integers defining the leftmost
// match of p in s. A return value of nil indicates no match.
func (p *Pattern) FindString(s string) []int {
	return nil
}

// FindLast returns a two-element slice of integers defining the rightmost
// match of p in b. A return value of nil indicates no match.
func (p *Pattern) FindLast(b []byte) []int {
	return nil
}

// FindLastString returns a two-element slice of integers defining the rightmost
// match of p in s. A return value of nil indicates no match.
func (p *Pattern) FindLastString(s string) []int {
	return nil
}

// FindAll returns a slice of successive matches of p in b, each represented
// by a two-element slice of integers. A return value of nil indicates no match.
func (p *Pattern) FindAll(b []byte) [][]int {
	return nil
}

// FindAllString returns a slice of successive matches of p in s, each represented
// by a two-element slice of integers. A return value of nil indicates no match.
func (p *Pattern) FindAllString(s string) [][]int {
	return nil
}
