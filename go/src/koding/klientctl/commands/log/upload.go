package log

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type uploadOptions struct{}

// NewUploadCommand creates a command that uploads log files to Koding.
func NewUploadCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &uploadOptions{}

	cmd := &cobra.Command{
		Use:   "upload",
		Short: "Share log files with Koding",
		RunE:  uploadCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func uploadCommand(c *cli.CLI, opts *uploadOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
