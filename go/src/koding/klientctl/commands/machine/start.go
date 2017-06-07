package machine

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type startOptions struct {
	jsonOutput bool
}

// NewStartCommand creates a command that can start a remote machine.
func NewStartCommand(c *cli.CLI) *cobra.Command {
	opts := &startOptions{}

	cmd := &cobra.Command{
		Use:   "start",
		Short: "Start remote machine",
		RunE:  startCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func startCommand(c *cli.CLI, opts *startOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
