package machine

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type sshOptions struct {
	username string
}

// NewSSHCommand creates a command that allows to SSH into remote machine.
func NewSSHCommand(c *cli.CLI) *cobra.Command {
	opts := &sshOptions{}

	cmd := &cobra.Command{
		Use:     "ssh <machine-identifier>",
		Aliases: []string{"s"},
		Short:   "SSH to remote machine",
		RunE:    sshCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.username, "username", "u", "", "remote username")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.ExactArgs(1),   // One argument must be provided.
	)(c, cmd)

	return cmd
}

func sshCommand(c *cli.CLI, opts *sshOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		sshOpts := &machine.SSHOptions{
			Identifier: args[0],
			Username:   opts.username,
			AskList:    cli.AskList(c, cmd),
		}

		return machine.SSH(sshOpts)
	}
}
