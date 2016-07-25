package goobj

import (
	"testing"
)

func TestFileSet(t *testing.T) {
	fset := new(FileSet)
	fset.Enter("runtime.c", 1)
	fset.Enter("runtime.h", 6)
	fset.Exit(882)
	fset.Enter("arch.h", 883)
	fset.Exit(887)
	fset.Exit(1278)

	test := func(pos int, file string, line int) {
		p := fset.Position(pos)
		pref := Position{File: file, Line: line}
		if p != pref {
			t.Errorf("got %s, expected %s", p, pref)
		}
	}

	test(985, "runtime.c", 105)
	test(16, "runtime.h", 11)
}
