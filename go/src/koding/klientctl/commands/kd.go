// Package commands defines the command line interface for kd executable.
package commands

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

// NewKdCommand creates a root command for kd.
func NewKdCommand(c *cli.CLI) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "kd [command]",
		Short: "kd is a CLI tool that allows user to interact with their infrastructure",
		Args:  cli.NoArgs,
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Add subcommands.
	// TODO: cmd.AddCommand()

	// Add middlewares.
	// TODO

	return cmd
}
