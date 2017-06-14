package cli

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

// TODO: Deprecate the middlewares when cobra/pull/284 is merged.

// NoArgs returns non-nil error when command is called with non zero arguments.
func NoArgs(cli *CLI, rootCmd *cobra.Command) {
	tail := rootCmd.PreRunE
	rootCmd.PreRunE = func(cmd *cobra.Command, args []string) error {
		if err := noArgs(cmd, args); err != nil {
			return err
		}

		if tail != nil {
			return tail(cmd, args)
		}

		return nil
	}
}

// noArgs returns non-nil error when command is called with arguments.
func noArgs(cmd *cobra.Command, args []string) error {
	if len(args) == 0 {
		return nil
	}

	if cmd.HasSubCommands() {
		return fmt.Errorf("unknown command %q for %q", strings.Join(args, " "), cmd.Name())
	}

	return fmt.Errorf("%q does not support any arguments", cmd.CommandPath())
}
