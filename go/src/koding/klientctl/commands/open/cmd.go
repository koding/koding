package open

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type options struct {
	debug bool
}

// NewCommand creates a command that is used to open provided files in Koding UI.
func NewCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "open",
		Short: "Open given files in Koding UI",
		RunE:  command(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.debug, "debug", false, "debug mode")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
