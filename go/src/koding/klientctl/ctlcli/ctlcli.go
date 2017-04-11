// ctlcli holds the interfaces and helpers for the current CLI library
// (codeganster/cli).
//
// Abstracting away any cli library implementation from the commands themselves,
// keeping our commands testable and generic.
package ctlcli

import (
	"fmt"
	"io"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
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

// Command is the basic interface for all klientctl commands.
type Command interface {
	// Run implements the main CLI function for running a command. Error is returned
	// in combination with the exit status for easy API usage.
	Run() (int, error)

	// Help, presents help to the user. However, many CLI libraries take care of the
	// Help presentation, such as formatting and args. This method usually calls back to
	// the parent CLI library via an internal reference to the ctlcli.Helper type. See
	// ctlcli.Helper docs for further explanation.
	Help()
}

// AutocompleteCommand is an interface for a Command that wants to provide
// Autocomplete functionality.
type AutocompleteCommand interface {
	// Autocomplete prints to Stdout what is to be autocompleted, one item per line.
	// Handling of the autocompletion is done by the shell (bash/fish/etc), this
	// method simply prints to Stdout.
	Autocomplete(args ...string) error
}

// Helper implements an abstraction between Commands and codegansta/cli. How the
// helpers are implemented varies depending on the actual Helper function we're
// wrapping, but typically they write the given io.Writer to the cli.Context
// before calling the cli.ShowHelp-like commands.
type Helper func(io.Writer)

// ExitingCommand is a function that returns an exit code
type ExitingCommand func(*cli.Context, logging.Logger, string) int

// ExitingErrCommand is a function that returns an exit code and an error. Behavior
// is the same as ExitingCommand, but it also supports an error return.
type ExitingErrCommand func(*cli.Context, logging.Logger, string) (int, error)

// CommandFactory returns a struct implementing the Command interface.
type CommandFactory func(*cli.Context, logging.Logger, string) Command

// CommandHelper maps the codegansta/cli Help to our generic Helper type.
// It does so by calling cli.ShowCommandHelper after setting the proper writer. For
// reference, see:
//
// cli.ShowCommandHelp https://github.com/codegangsta/cli/blob/master/help.go#L104
//
// The context and command for this are typically provided by the command factory.
func CommandHelper(ctx *cli.Context, cmd string) Helper {
	return func(w io.Writer) {
		ctx.App.Writer = w
		cli.ShowCommandHelp(ctx, cmd)
	}
}

// ExitAction implements a cli.Command's Action field for an ExitingCommand type.
func ExitAction(f ExitingCommand, log logging.Logger, cmdName string) cli.ActionFunc {
	eec := func(c *cli.Context, log logging.Logger, cmdName string) (int, error) {
		return f(c, log, cmdName), nil
	}

	return ExitErrAction(eec, log, cmdName)
}

// FactoryAction implements a cli.Command's Action field.
func FactoryAction(factory CommandFactory, log logging.Logger, cmdName string) cli.ActionFunc {
	eec := func(c *cli.Context, log logging.Logger, cmdName string) (int, error) {
		return factory(c, log, cmdName).Run()
	}

	return ExitErrAction(eec, log, cmdName)
}

// ExitErrAction implements a cli.Command's Action field for an ExitingErrCommand
func ExitErrAction(f ExitingErrCommand, log logging.Logger, cmdName string) cli.ActionFunc {
	return func(c *cli.Context) error {
		defer Close()

		exit, err := f(c, log, cmdName)
		if err != nil || exit != 0 {
			log.Error("Command %q encountered error. Exit:%d, err:%v", cmdName, exit, err)

			msg := fmt.Sprintf("error executing %q command", cmdName)
			if err != nil {
				msg = msg + ": " + err.Error()
			}

			// Print error message to the user.
			return cli.NewExitError(msg, exit)
		}

		return nil
	}
}

// FactoryCompletion implements codeganstas cli.Command's bash completion field
func FactoryCompletion(factory CommandFactory, log logging.Logger, cmdName string) cli.BashCompleteFunc {
	return func(c *cli.Context) {
		cmd := factory(c, log, cmdName)

		// If the command implements AutocompleteCommand, run the autocomplete.
		if aCmd, ok := cmd.(AutocompleteCommand); ok {
			if err := aCmd.Autocomplete(c.Args()...); err != nil {
				log.Error(
					"Autocompletion of a command encountered error. command:%s, err:%s",
					cmdName, err,
				)
			}
		}
	}
}
