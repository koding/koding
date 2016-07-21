package goobj

import (
	"fmt"
)

type Version int

const (
	GO1 Version = iota
	GO1_1
)

// A FileSet holds line information for a set of files.
// Unlike FileSet from go/token, a file may include other
// files and span a discontinuous set of line numbers.
type FileSet []FileSetBound

type FileSetBound struct {
	Enter bool
	Line  int
	Name  string
}

func (fs *FileSet) Enter(filename string, line int) {
	*fs = append(*fs, FileSetBound{Enter: true, Line: line, Name: filename})
}

func (fs *FileSet) Exit(line int) {
	*fs = append(*fs, FileSetBound{Enter: false, Line: line})
}

type Position struct {
	Filename string
	Line     int
}

func (fs *FileSet) Position(line int) Position {
	last := -1
	for i, bound := range *fs {
		if bound.Line <= line {
			last = i
		}
	}
	// Find the last entry point.
	depth := 0
	skipped := 0
	for ; last >= 0; last-- {
		ev := (*fs)[last]
		if !ev.Enter {
			depth++
			if depth == 1 {
				skipped += ev.Line
			}
		} else {
			if depth == 1 {
				skipped -= ev.Line
			}
			if depth == 0 {
				// Found.
				return Position{Filename: ev.Name, Line: line - ev.Line + 1 - skipped}
			}
			depth--
		}
	}
	return Position{Line: line}
}

func (pos Position) String() string {
	return fmt.Sprintf("%s:%d", pos.Filename, pos.Line)
}
