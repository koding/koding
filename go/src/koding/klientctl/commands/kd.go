// Package commands defines the command line interface for kd executable.
package commands

import (
	"koding/klientctl/commands/auth"
	"koding/klientctl/commands/bug"
	"koding/klientctl/commands/cli"
	"koding/klientctl/commands/config"
	"koding/klientctl/commands/cred"
	"koding/klientctl/commands/daemon"
	"koding/klientctl/commands/initial"
	"koding/klientctl/commands/log"
	"koding/klientctl/commands/machine"
	"koding/klientctl/commands/machine/mount"
	"koding/klientctl/commands/machine/mount/sync"
	"koding/klientctl/commands/metrics"
	"koding/klientctl/commands/open"
	"koding/klientctl/commands/stack"
	"koding/klientctl/commands/status"
	"koding/klientctl/commands/team"
	"koding/klientctl/commands/template"
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
		bug.NewCommand(c),
		auth.NewCommand(c),
		config.NewCommand(c),
		cred.NewCommand(c),
		daemon.NewCommand(c),
		daemon.NewInstallCommand(c, "kd", "daemon"),
		daemon.NewRestartCommand(c, "kd", "daemon"),
		daemon.NewStartCommand(c, "kd", "daemon"),
		daemon.NewStopCommand(c, "kd", "daemon"),
		daemon.NewUninstallCommand(c, "kd", "daemon"),
		daemon.NewUpdateCommand(c, "kd", "daemon"),
		initial.NewCommand(c),
		log.NewCommand(c),
		machine.NewCommand(c),
		machine.NewCpCommand(c, "kd", "machine"),
		machine.NewExecCommand(c, "kd", "machine"),
		machine.NewListCommand(c, "kd", "machine"),
		machine.NewSSHCommand(c, "kd", "machine"),
		machine.NewUmountCommand(c, "kd", "machine"),
		metrics.NewCommand(c),
		mount.NewCommand(c, "kd", "machine"),
		open.NewCommand(c),
		stack.NewCommand(c),
		status.NewCommand(c),
		sync.NewCommand(c, "kd", "machine", "mount"),
		team.NewCommand(c),
		template.NewCommand(c),
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
