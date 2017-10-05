// Copyright 2017 The Go Authors.  All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package x86csv

import (
	"encoding/csv"
	"io"
)

// A Reader reads entries from an "x86.csv" file.
type Reader struct {
	csv *csv.Reader
}

// NewReader returns a Reader reading from r, which should
// be of the content of the "x86.csv" (format version=0.2).
func NewReader(r io.Reader) *Reader {
	rcsv := csv.NewReader(r)
	rcsv.Comment = '#'
	return &Reader{csv: rcsv}
}

// ReadAll reads all remaining rows from r.
//
// If error is occured, still returns all rows
// that have been read during method execution.
//
// A successful call returns err == nil, not err == io.EOF.
// Because ReadAll is defined to read until EOF,
// it does not treat end of file as an error to be reported.
func (r *Reader) ReadAll() ([]*Inst, error) {
	var err error
	var insts []*Inst
	for inst, err := r.Read(); err == nil; inst, err = r.Read() {
		insts = append(insts, inst)
	}
	if err == io.EOF {
		return insts, nil
	}
	return insts, err
}

// Read reads and returns the next Row from the "x86.csv" file.
// If there is no data left to be read, Read returns {nil, io.EOF}.
func (r *Reader) Read() (*Inst, error) {
	cols, err := r.csv.Read()
	if err != nil {
		return nil, err
	}

	// This should be the only place where indexes
	// are used. Everything else should rely on Row records.
	inst := &Inst{
		Intel:     cols[0],
		Go:        cols[1],
		GNU:       cols[2],
		Encoding:  cols[3],
		Mode32:    cols[4],
		Mode64:    cols[5],
		CPUID:     cols[6],
		Tags:      cols[7],
		Action:    cols[8],
		Multisize: cols[9],
		Size:      cols[10],
	}
	return inst, nil
}
