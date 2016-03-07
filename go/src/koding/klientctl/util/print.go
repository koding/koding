package util

import (
	"fmt"
	"io"
)

// Fprint is a simple struct which implements various Fprint methods to the internal
// Writer.
//
// Fprints methods will panic if used without a Writer, in the same way that
// fmt.Fprint will panic without a writer.
type Fprint struct {
	io.Writer
}

func NewFprint(w io.Writer) *Fprint {
	return &Fprint{
		Writer: w,
	}
}

// Fprintlnf combines a formatted Fprintf and includes a newline character.
func Fprintlnf(w io.Writer, f string, i ...interface{}) {
	fmt.Fprintf(w, f+"\n", i...)
}

func (p *Fprint) Printf(f string, i ...interface{}) {
	fmt.Fprintf(p.Writer, f, i...)
}

// Printlnf implements Fprintlnf for the Fprint struct.
func (p *Fprint) Printlnf(f string, i ...interface{}) {
	Fprintlnf(p.Writer, f, i...)
}
