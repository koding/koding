// Package commands defines the command line interface for kd executable.
package commands

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/commands/machine"
	"koding/klientctl/commands/version"

	"github.com/spf13/cobra"
)

// NewKdCommand creates a root command for kd.
func NewKdCommand(c *cli.CLI) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "kd [command]",
		Short: "kd is a CLI tool that allows user to interact with their infrastructure.",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		machine.NewCommand(c),
		machine.NewListCommand(c, "machine", "list"),
		version.NewCommand(c),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.ApplyForAll(cli.CloseOnExitCtlCli),    // Run ctlcli.Close for all commands.
		cli.ApplyForAll(cli.WithLoggedInfo),       // Log invocation and errors for all commands.
		cli.ApplyForAll(cli.WithInitializedCache), // Use cache for all commands.
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
