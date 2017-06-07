package machine

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type stopOptions struct {
	jsonOutput bool
}

// NewStopCommand creates a command that can stop a remote machine.
func NewStopCommand(c *cli.CLI) *cobra.Command {
	opts := &stopOptions{}

	cmd := &cobra.Command{
		Use:   "stop",
		Short: "Stop remote machine",
		RunE:  stopCommand(c, opts),
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

func stopCommand(c *cli.CLI, opts *stopOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
