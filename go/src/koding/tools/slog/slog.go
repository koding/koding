// Slog is an abbrevation for simplelog. It uses by default stdout as the output
// destination and has features like defining multiple output destinations
// (like stdout and file at the same time), prefix pretending with a function call
// and global switch to turn off/on logs.
package slog

import (
	"errors"
	"fmt"
	"io"
	"os"
	"sync"
	"time"
)

// A slog represents an object that generates lines of output to to an
// io.Writer. By default it uses os.Stdout, but it can be changed  or others
// may be included during creation.
type Slog struct {
	mu      sync.Mutex    // protects the following fields
	disable bool          // global switch to disable log completely
	prefix  func() string // function return is written at beginning of each line
	out     io.Writer     // destination for ouput
}

var stdlog = New()

// New creates a new slog. The filepath sets the files that will be used
// as an extra output destination. By default slog outputs to stdout.
func New(filepath ...string) *Slog {
	writers := make([]io.Writer, 0)
	for _, path := range filepath {
		logFile, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0640)
		if err != nil {
			fmt.Printf("slog: can't open %s: '%s'\n", path, err)
			continue
		}

		writers = append(writers, logFile)
	}

	writers = append(writers, os.Stdout)

	return &Slog{
		out: io.MultiWriter(writers...),
		prefix: func() string {
			return fmt.Sprintf("[%s] ", time.Now().Format(time.Stamp))
		},
	}
}

// Print calls Output to print to the standard logger. Arguments are handled in
// the manner of fmt.Print.
func Printn(v ...interface{}) (int, error) {
	if stdlog.disable {
		return 0, nil
	}

	return fmt.Fprint(stdlog.output(), v...)
}

// Printf calls Output to print to the standard logger. Arguments are handled in
// the manner of fmt.Printf.
func Printf(format string, v ...interface{}) (int, error) {
	if stdlog.disable {
		return 0, nil
	}

	return fmt.Fprintf(stdlog.output(), format, v...)
}

// Println calls Output to print to the standard logger. Arguments are handled in
// the manner of fmt.Println.
func Println(v ...interface{}) (int, error) {
	if stdlog.disable {
		return 0, nil
	}

	return fmt.Fprintln(stdlog.output(), v...)
}

// SetPrefix sets the output prefix according to the return value of the passed
// function for the standard logger.
func SetPrefix(fn func() string) {
	stdlog.mu.Lock()
	defer stdlog.mu.Unlock()
	stdlog.prefix = fn
}

// Prefix returns the output prefix for the standard logger.
func Prefix() string {
	stdlog.mu.Lock()
	defer stdlog.mu.Unlock()
	return stdlog.prefix()
}

// SetOutput replaces the standard destination for the standard logger.
func SetOutput(out io.Writer) {
	stdlog.mu.Lock()
	defer stdlog.mu.Unlock()
	stdlog.out = out
}

// SetOutputFile defines a new file destination for the output. That means
// if used, it will store the stdout to an external file too.
func SetOutputFile(path string) error {
	if path == "" {
		errors.New("slog: arg for SetOutputFile sould be not empty")
	}

	writers := make([]io.Writer, 0)
	logFile, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE, 0640)
	if err != nil {
		return fmt.Errorf("slog: can't open %s: '%s'\n", path, err)
	} else {
		stdlog.mu.Lock()
		defer stdlog.mu.Unlock()

		writers = append(writers, logFile, os.Stdout)
		stdlog.out = io.MultiWriter(writers...)
	}

	return nil
}

// DisableLog is a global switch that disables the output completely for the
// standard logger. Useful if you want turn off/on logs for debugging.
func DisableLog() {
	stdlog.mu.Lock()
	defer stdlog.mu.Unlock()
	stdlog.disable = true
}

// Print formats using the default formats for its operands and writes to
// standard output. Spaces are added between operands when neither is a string. It
// returns the number of bytes written and any write error encountered.
func (s *Slog) Printn(v ...interface{}) (int, error) {
	if s.disable {
		return 0, nil
	}

	return fmt.Fprint(s.output(), v...)
}

// Printf formats according to a format specifier and writes to standard output.
// It returns the number of bytes written and any write error encountered.
func (s *Slog) Printf(format string, v ...interface{}) (int, error) {
	if s.disable {
		return 0, nil
	}

	return fmt.Fprintf(s.output(), format, v...)
}

// Println formats using the default formats for its operands and writes to
// standard output. Spaces are always added between operands and a newline is
// appended. It returns the number of bytes written and any write error
// encountered.
func (s *Slog) Println(v ...interface{}) (int, error) {
	if s.disable {
		return 0, nil
	}

	return fmt.Fprintln(s.output(), v...)
}

// SetPrefix sets the output prefix according to the return value of the passed
// function.
func (s *Slog) SetPrefix(fn func() string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.prefix = fn
}

// Prefix returns the output prefix.
func (s *Slog) Prefix() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.prefix()
}

// SetOutput replaces the standard destination.
func (s *Slog) SetOutput(out io.Writer) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.out = out
}

// DisableLog is a global switch that disables the output completely. Useful
// if you want turn off/on logs for debugging.
func (s *Slog) DisableLog() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.disable = true
}

func (s *Slog) output() io.Writer {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.out.Write([]byte(s.prefix()))
	return s.out
}
