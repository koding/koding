// Package commands defines the command line interface for kd executable.
package commands

import (
	"koding/klientctl/ctlcli"

	"github.com/spf13/cobra"
)

// CloseOnExitCtlCli creates a wrapper on ctlcli finalizer function that closes
// all registered io.Closers after cobra command is finished. Subcommands also
// inherit this call.
func CloseOnExitCtlCli(_ *CLI, cmd *cobra.Command) {
	f := func(_ *cobra.Command, _ []string) error {
		ctlcli.Close()
		return nil
	}

	cmd.PersistentPostRunE = UnionCobraFuncE(cmd.PersistentPostRunE, f)
}
