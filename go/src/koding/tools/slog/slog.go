// Slog is an abbrevation for simplelog. It uses by default stdout as the output
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
	mu         sync.Mutex    // protects the following fields
	disable    bool          // global switch to disable log completely
	prefixFunc func() string // if set function return is used instead of prefix
	prefix     struct {
		name       string // is written at beginning of each line
		timeLayout string // is written after prefix.name, used for time.Format()
	}
	out io.Writer // destination for ouput
}

var stdlog = New("", time.StampMilli)

// New creates a new slog. prefixName is written at the beginning of each line.
// prefixTimeStamp comes after prefixName and is used to define the time
// layout. This should usually in form of : time.RFC3339, time.Kitchen,
// time.UnixDate etc. The filepath sets the files that will be used as an extra
// output destination. By default slog outputs to stdout.
func New(prefixName, prefixTimeStamp string, filepath ...string) *Slog {
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

	s := &Slog{
		out: io.MultiWriter(writers...),
	}

	s.prefix.name = prefixName
	s.prefix.timeLayout = prefixTimeStamp
	return s
}

// Print calls Output to print to the standard logger. Arguments are handled in
// the manner of fmt.Print.
func Print(v ...interface{}) (int, error) {
	return stdlog.checkDisable(func() (int, error) {
		return fmt.Fprint(stdlog.output(), v...)
	})
}

// Printf calls Output to print to the standard logger. Arguments are handled in
// the manner of fmt.Printf.
func Printf(format string, v ...interface{}) (int, error) {
	return stdlog.checkDisable(func() (int, error) {
		return fmt.Fprintf(stdlog.output(), format, v...)
	})
}

// Println calls Output to print to the standard logger. Arguments are handled in
// the manner of fmt.Println.
func Println(v ...interface{}) (int, error) {
	return stdlog.checkDisable(func() (int, error) {
		return fmt.Fprintln(stdlog.output(), v...)
	})
}

// Fatal is equivalent to Print() followed by a call to os.Exit(1).
func Fatal(v ...interface{}) {
	stdlog.checkDisable(func() (int, error) {
		Print(v...)
		os.Exit(1)
		return 0, nil
	})
}

// Fatalf is equivalent to Printf() followed by a call to os.Exit(1).
func Fatalf(format string, v ...interface{}) {
	stdlog.checkDisable(func() (int, error) {
		Printf(format, v...)
		os.Exit(1)
		return 0, nil
	})
}

// Fatalln is equivalent to Println() followed by a call to os.Exit(1).
func Fatalln(v ...interface{}) {
	stdlog.checkDisable(func() (int, error) {
		Println(v...)
		os.Exit(1)
		return 0, nil
	})
}

// SetPrefixFunc sets the output prefix according to the return value of the passed
// function for the standard logger. This replaces PrefixName and PrefixTimeStamp.
func SetPrefixFunc(fn func() string) {
	stdlog.mu.Lock()
	defer stdlog.mu.Unlock()
	stdlog.prefixFunc = fn
}

// Prefix returns the output prefix for the standard logger.
func Prefix() string {
	stdlog.mu.Lock()
	defer stdlog.mu.Unlock()
	return stdlog.prefixOutput()
}

// DisablePrefix disables the prefix generator for the standard logger. That
// means it will reset the current prefix generation function.
func DisablePrefix() {
	stdlog.mu.Lock()
	defer stdlog.mu.Unlock()
	stdlog.prefixFunc = func() string { return "" }
}

// SetPrefixName adds an additional prefix to the beginning of each line for the
// standard logger. Useful to add an application name. By default no PrefixName
// is defined
func SetPrefixName(name string) {
	stdlog.prefix.name = name
}

// SetPrefixTimeStamp changes the timestamp that is appended after the
// PrefixName for the standard logger. It's passed to time.Format() and is
// excepting layouts in form of : time.RFC3339, time.Kitchen, time.UnixDate ...
// The standard logger is using the layout time.StampMilli by default.
func SetPrefixTimeStamp(layout string) {
	stdlog.prefix.timeLayout = layout
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
		return errors.New("slog: arg for SetOutputFile sould be not empty")
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
func (s *Slog) Print(v ...interface{}) (int, error) {
	return s.checkDisable(func() (int, error) {
		return fmt.Fprint(s.output(), v...)
	})
}

// Printf formats according to a format specifier and writes to standard output.
// It returns the number of bytes written and any write error encountered.
func (s *Slog) Printf(format string, v ...interface{}) (int, error) {
	return s.checkDisable(func() (int, error) {
		return fmt.Fprintf(s.output(), format, v...)
	})
}

// Println formats using the default formats for its operands and writes to
// standard output. Spaces are always added between operands and a newline is
// appended. It returns the number of bytes written and any write error
// encountered.
func (s *Slog) Println(v ...interface{}) (int, error) {
	return s.checkDisable(func() (int, error) {
		return fmt.Fprintln(s.output(), v...)
	})
}

// Fatal is equivalent to s.Print() followed by a call to os.Exit(1).
func (s *Slog) Fatal(v ...interface{}) {
	s.checkDisable(func() (int, error) {
		s.Print(v...)
		os.Exit(1)
		return 0, nil
	})
}

// Fatalf is equivalent to s.Printf() followed by a call to os.Exit(1).
func (s *Slog) Fatalf(format string, v ...interface{}) {
	s.checkDisable(func() (int, error) {
		s.Printf(format, v...)
		os.Exit(1)
		return 0, nil
	})
}

// Fatalln is equivalent to s.Println() followed by a call to os.Exit(1).
func (s *Slog) Fatalln(v ...interface{}) {
	s.checkDisable(func() (int, error) {
		s.Println(v...)
		os.Exit(1)
		return 0, nil
	})
}

// SetPrefixFunc sets the output prefix according to the return value of the passed
// function.  This replaces PrefixName and PrefixTimeStamp.
func (s *Slog) SetPrefixFunc(fn func() string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.prefixFunc = fn
}

// Prefix returns the output prefix.
func (s *Slog) Prefix() string {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.prefixOutput()
}

// DisablePrefix disables the prefix generator. That means it will reset the current
// prefix generation function.
func (s *Slog) DisablePrefix() {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.prefixFunc = func() string { return "" }
}

// SetPrefixName adds an additional prefix to the beginning of each line.
// Useful to add an application name. By default no PrefixName is defined.
func (s *Slog) SetPrefixName(name string) {
	s.prefix.name = name
}

// SetPrefixTimeStamp changes the timestamp that is appended after the
// PrefixName. It's passed to time.Format() and is excepting layouts in form of:
// time.RFC3339, time.Kitchen, time.UnixDate etc. By default time.StampMilli is
// used.
func (s *Slog) SetPrefixTimeStamp(layout string) {
	s.prefix.timeLayout = layout
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

// output writes to the io.Writers we specified before and returns the writer
// back.
func (s *Slog) output() io.Writer {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.out.Write([]byte(s.prefixOutput()))
	return s.out
}

// prefixOutput either writes in for of [prefixName prefixTimestamp] or invokes
// the custom prefixFunc() if any created.
func (s *Slog) prefixOutput() string {
	if s.prefixFunc != nil {
		return s.prefixFunc()
	}

	if s.prefix.name == "" {
		return fmt.Sprintf("[%s] ", time.Now().Format(s.prefix.timeLayout))
	}
	return fmt.Sprintf("[%s %s] ", s.prefix.name, time.Now().Format(s.prefix.timeLayout))
}

// Check if our globale disable switch is activated. If enabled don't execute
// our print function.
func (s *Slog) checkDisable(fn func() (int, error)) (int, error) {
	if s.disable {
		return 0, nil
	}

	return fn()
}
