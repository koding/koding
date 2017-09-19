package ctlcli

import (
	"io"
)

var closers []io.Closer

// CloseFunc wraps func to provide an implementation for the io.Closer interface.
type CloseFunc func() error

// Close implements the io.Closer interface.
func (c CloseFunc) Close() error { return c() }

// CloseOnExit is a hack to close program-lifetime-bound resources,
// like log file or BoltDB database.
func CloseOnExit(c io.Closer) {
	closers = append(closers, c)
}

// Close is a hack to close program-lifetime-bound resources,
// like log file or BoltDB database.
func Close() {
	for i := len(closers) - 1; i >= 0; i-- {
		closers[i].Close()
	}
}

// Helper implements an abstraction between Commands and codegansta/cli. How the
// helpers are implemented varies depending on the actual Helper function we're
// wrapping, but typically they write the given io.Writer to the cli.Context
// before calling the cli.ShowHelp-like commands.
type Helper func(io.Writer)
