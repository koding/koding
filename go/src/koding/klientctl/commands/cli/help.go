package cli

import (
	"errors"
	"io"

	"github.com/spf13/cobra"
)

// HelpForNoFlags handles help flags when DisableFlagParsing option is enabled
// for the command.
func HelpForNoFlags(cli *CLI, rootCmd *cobra.Command) {
	tail := rootCmd.PreRunE
	rootCmd.PreRunE = func(cmd *cobra.Command, args []string) error {
		if len(args) == 1 && (args[0] == "-h" || args[0] == "--help") {
			PrintHelp(cli.Err())(cmd, args)

			// Break command execution.
			cmd.SilenceErrors = true
			cmd.SilenceUsage = true
			return NewError(0, errors.New("help called"))
		}

		if tail != nil {
			return tail(cmd, args)
		}

		return nil
	}
}

// PrintHelp creates cobra handler that prints help for provided function to
// provider writer.
func PrintHelp(w io.Writer) CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		cmd.SetOutput(w)
		cmd.HelpFunc()(cmd, args)
		return nil
	}
}
