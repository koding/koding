package cli

import (
	"strings"

	"github.com/spf13/cobra"
)

// WithLoggedInfo logs command invocation details and errors if any.
func WithLoggedInfo(cli *CLI, rootCmd *cobra.Command) {
	tail := rootCmd.RunE
	if tail == nil {
		panic("cannot insert middleware into empty function")
	}

	rootCmd.RunE = func(cmd *cobra.Command, args []string) (err error) {
		cli.Log().Info("Command %q, called with arguments %q",
			cmd.CommandPath(),
			strings.Join(args, " "),
		)

		if err = tail(cmd, args); err != nil {
			cli.Log().Error("Command %q exited with error: %s (exit code: %d)",
				cmd.CommandPath(),
				err, ExitCodeFromError(err),
			)
		}

		return
	}
}
