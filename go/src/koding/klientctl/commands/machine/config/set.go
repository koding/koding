package config

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type setOptions struct{}

// NewSetCommand creates a command that allows to set configuration field.
func NewSetCommand(c *cli.CLI) *cobra.Command {
	opts := &setOptions{}

	cmd := &cobra.Command{
		Use:   "set <machine-id> <key> <value>",
		Short: "Set configuration value",
		RunE:  setCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.ExactArgs(3),   // Three arguments are accepted.
	)(c, cmd)

	return cmd
}

func setCommand(c *cli.CLI, opts *setOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return machine.Set(&machine.SetOptions{
			Identifier: args[0],
			Key:        args[1],
			Value:      args[2],
			AskList:    cli.AskList(c, cmd),
		})
	}
}
