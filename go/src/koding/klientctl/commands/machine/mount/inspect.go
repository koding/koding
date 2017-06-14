package mount

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type inspectOptions struct {
	filesystem bool
	tree       bool
	sync       bool
}

// NewInspectCommand creates a command that allows to debug existing mount state.
func NewInspectCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &inspectOptions{}

	cmd := &cobra.Command{
		Use:    "inspect",
		Short:  "Show mount debug information",
		RunE:   inspectCommand(c, opts),
		Hidden: true,
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.filesystem, "filesystem", false, "filesystem diagnostic")
	flags.BoolVar(&opts.tree, "tree", false, "index internal state")
	flags.BoolVar(&opts.sync, "sync", true, "sync events history")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func inspectCommand(c *cli.CLI, opts *inspectOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
