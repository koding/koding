package machine

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type sshOptions struct {
	username string
}

// NewSSHCommand creates a command that allows to SSH into remote machine.
func NewSSHCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &sshOptions{}

	cmd := &cobra.Command{
		Use:     "ssh",
		Aliases: []string{"s"},
		Short:   "SSH to remote machine",
		RunE:    sshCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.username, "username", "u", "", "remote username")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func sshCommand(c *cli.CLI, opts *sshOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
