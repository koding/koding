// Copyright 2013, Örjan Persson. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package logging

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"regexp"
	"sync"
	"time"
)

// TODO see Formatter interface in fmt/print.go
// TODO try text/template, maybe it have enough performance
// TODO other template systems?
// TODO make it possible to specify formats per backend?
type fmtVerb int

const (
	fmtVerbTime fmtVerb = iota
	fmtVerbLevel
	fmtVerbId
	fmtVerbModule
	fmtVerbMessage

	// Keep last, there are no match for these below.
	fmtVerbUnknown
	fmtVerbStatic
)

var fmtVerbs = []string{
	"time",
	"level",
	"id",
	"module",
	"message",
}

var defaultVerbsLayout = []string{
	"2006-01-02T15:04:05.999Z-07:00",
	"s",
	"d",
	"s",
	"s",
}

func getFmtVerbByName(name string) fmtVerb {
	for i, verb := range fmtVerbs {
		if name == verb {
			return fmtVerb(i)
		}
	}
	return fmtVerbUnknown
}

// Formatter is the required interface for a custom log record formatter.
type Formatter interface {
	Format(*Record, io.Writer) error
}

// formatter is used by all backends unless otherwise overriden.
var formatter struct {
	sync.RWMutex
	def Formatter
}

func getFormatter() Formatter {
	formatter.RLock()
	defer formatter.RUnlock()
	return formatter.def
}

var (
	// DefaultFormatter is the default formatter used and is only the message.
	DefaultFormatter Formatter = MustStringFormatter("%{message}")

	// TODO add filename and line
	// GlogFormatter Formatter = MustStringFormatter("%{level:.1}%%{time:0102 15:04:05.99999} 0 %{file}:%{line} %{message}")
)

// SetFormatter sets the default formatter for all new backends. A backend will
// fetch this value once it is needed to format a record. Note that backends
// will cache the formatter after the first point. For now, make sure to set
// the formatter before logging.
func SetFormatter(f Formatter) {
	formatter.Lock()
	defer formatter.Unlock()
	formatter.def = f
}

// TODO use ${} instead?
var formatRe *regexp.Regexp = regexp.MustCompile(`%{([a-z]+)(?::(.*?[^\\]))?}`)

type part struct {
	verb   fmtVerb
	layout string
}

// stringFormatter contains a list of parts which explains how to build the
// formatted string passed on to the logging backend.
type stringFormatter struct {
	parts []part
}

// NewStringFormatter returns a new Formatter which outputs the log record as a
// string based on the 'verbs' specified in the format string.
//
// The verbs:
//
// General:
//     %{id}      Sequence number for log message (uint64).
//     %{time}    Time when log occurred (time.Time)
//     %{level}   Log level (Level)
//     %{module}  Module (string)
//     %{message} Message (string)
//
// For normal types, the output can be customized by using the 'verbs' defined
// in the fmt package, eg. '%{id:04d}' to make the id output be '%04d' as the
// format string.
//
// For time.Time, use the same layout as time.Format to change the time format
// when output, eg "2006-01-02T15:04:05.999Z-07:00".
func NewStringFormatter(format string) (*stringFormatter, error) {
	var fmter = &stringFormatter{}

	// Find the boundaries of all %{vars}
	matches := formatRe.FindAllStringSubmatchIndex(format, -1)
	if matches == nil {
		return nil, errors.New("logger: invalid log format: " + format)
	}

	// Collect all variables and static text for the format
	prev := 0
	for _, m := range matches {
		start, end := m[0], m[1]
		if start > prev {
			fmter.add(fmtVerbStatic, format[prev:start])
		}

		name := format[m[2]:m[3]]
		verb := getFmtVerbByName(name)
		if verb == fmtVerbUnknown {
			return nil, errors.New("logger: unknown variable: " + name)
		}

		// Handle layout customizations or use the default. If this is not for the
		// time formatting, we need to prefix with %.
		layout := defaultVerbsLayout[verb]
		if m[4] != -1 {
			layout = format[m[4]:m[5]]
		}
		if verb != fmtVerbTime {
			layout = "%" + layout
		}

		fmter.add(verb, layout)
		prev = end
	}
	end := format[prev:]
	if end != "" {
		fmter.add(fmtVerbStatic, end)
	}

	// Make a test run to make sure we can format it correctly.
	t, err := time.Parse(time.RFC3339, "2010-02-04T21:00:57-08:00")
	if err != nil {
		panic(err)
	}
	r := &Record{
		Id:     12345,
		Time:   t,
		Module: "logger",
		fmt:    "hello %s",
		args:   []interface{}{"go"},
	}
	if err := fmter.Format(r, &bytes.Buffer{}); err != nil {
		return nil, err
	}

	formatter.def = fmter

	return fmter, nil
}

// MustStringFormatter is equivalent to NewStringFormatter with a call to panic
// on error.
func MustStringFormatter(format string) *stringFormatter {
	f, err := NewStringFormatter(format)
	if err != nil {
		panic("Failed to initialized string formatter: " + err.Error())
	}
	return f
}

func (f *stringFormatter) add(verb fmtVerb, layout string) {
	f.parts = append(f.parts, part{verb, layout})
}

func (f *stringFormatter) Format(r *Record, output io.Writer) error {
	// TODO collect and call fprintf once?
	for _, part := range f.parts {
		if part.verb == fmtVerbStatic {
			output.Write([]byte(part.layout))
		} else if part.verb == fmtVerbTime {
			output.Write([]byte(r.Time.Format(part.layout)))
		} else {
			var v interface{}
			switch part.verb {
			case fmtVerbLevel:
				v = r.Level
				break
			case fmtVerbId:
				v = r.Id
				break
			case fmtVerbModule:
				v = r.Module
				break
			case fmtVerbMessage:
				v = r.Message()
				break
			default:
				panic("unhandled format part")
			}
			fmt.Fprintf(output, part.layout, v)
		}
	}
	return nil
}
