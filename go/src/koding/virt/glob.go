// Copyright 2010 The Go Authors. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
//
// Richard: Modified excerpt of Go's match.go that uses VOS.

// +build linux

package virt

import (
	"path/filepath"
	"sort"
	"strings"
)

// Glob returns the names of all files matching pattern or nil
// if there is no matching file. The syntax of patterns is the same
// as in Match. The pattern may describe hierarchical names such as
// /usr/*/bin/ed (assuming the Separator is '/').
//
func (vos *VOS) Glob(pattern string) (matches []string, err error) {
	if !hasMeta(pattern) {
		if _, err = vos.Stat(pattern); err != nil {
			return nil, nil
		}
		return []string{pattern}, nil
	}

	dir, file := filepath.Split(pattern)
	switch dir {
	case "":
		dir = "."
	case string(filepath.Separator):
		// nothing
	default:
		dir = dir[0 : len(dir)-1] // chop off trailing separator
	}

	if !hasMeta(dir) {
		return vos.glob(dir, file, nil)
	}

	var m []string
	m, err = vos.Glob(dir)
	if err != nil {
		return
	}
	for _, d := range m {
		matches, err = vos.glob(d, file, matches)
		if err != nil {
			return
		}
	}
	return
}

// glob searches for files matching pattern in the directory dir
// and appends them to matches. If the directory cannot be
// opened, it returns the existing matches. New matches are
// added in lexicographical order.
func (vos *VOS) glob(dir, pattern string, matches []string) (m []string, e error) {
	m = matches
	fi, err := vos.Stat(dir)
	if err != nil {
		return
	}
	if !fi.IsDir() {
		return
	}
	d, err := vos.Open(dir)
	if err != nil {
		return
	}
	defer d.Close()

	names, err := d.Readdirnames(-1)
	if err != nil {
		return
	}
	sort.Strings(names)

	for _, n := range names {
		matched, err := filepath.Match(pattern, n)
		if err != nil {
			return m, err
		}
		if matched {
			m = append(m, filepath.Join(dir, n))
		}
	}
	return
}

// hasMeta returns true if path contains any of the magic characters
// recognized by Match.
func hasMeta(path string) bool {
	// TODO(niemeyer): Should other magic characters be added here?
	return strings.IndexAny(path, "*?[") >= 0
}
