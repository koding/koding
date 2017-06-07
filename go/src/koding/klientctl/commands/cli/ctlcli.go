package cli

import (
	"koding/klientctl/ctlcli"

	"github.com/spf13/cobra"
)

// CloseOnExitCtlCli creates a wrapper on ctlcli finalizer function that closes
// all registered io.Closers after cobra command is finished.
func CloseOnExitCtlCli(_ *CLI, rootCmd *cobra.Command) {
	tail := rootCmd.RunE
	if tail == nil {
		panic("cannot insert middleware into empty function")
	}

	rootCmd.RunE = func(cmd *cobra.Command, args []string) error {
		defer ctlcli.Close()

		return tail(cmd, args)
	}
}
