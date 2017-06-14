package cli

import (
	"fmt"

	"koding/klientctl/daemon"

	"github.com/spf13/cobra"
)

// DaemonRequired returns an error when klient daemon is not installed.
func DaemonRequired(cli *CLI, rootCmd *cobra.Command) {
	cli.registerMiddleware("daemon_required", rootCmd)
	tail := rootCmd.RunE
	if tail == nil {
		panic("cannot insert middleware into empty function")
	}

	rootCmd.RunE = func(cmd *cobra.Command, args []string) error {
		if daemon.Installed() {
			return tail(cmd, args)
		}

		var installHelp string
		if installCommand, _, err := cmd.Root().Find([]string{"install"}); err == nil {
			installHelp = fmt.Sprintf("\nSee: '%s --help' for help.\n\nUsage:  %s\n\n%s",
				installCommand.CommandPath(),
				installCommand.UseLine(),
				installCommand.Short,
			)
		}

		return fmt.Errorf(
			"%q requires the deamon to be installed.%s",
			cmd.CommandPath(),
			installHelp,
		)
	}
}
