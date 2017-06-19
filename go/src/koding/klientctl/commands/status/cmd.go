package status

import (
	"fmt"

	"koding/klientctl/commands/cli"
	"koding/klientctl/status"

	"github.com/spf13/cobra"
)

type options struct{}

// NewCommand creates a command that can be used to check KD status.
func NewCommand(c *cli.CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "status",
		Short: "Check service status",
		Long:  "This command checks if kd is installed and operative.",
		RunE:  command(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		res, ok := status.NewDefaultHealthChecker(c.Log()).CheckAllWithResponse()
		fmt.Fprintln(c.Out(), res)
		if !ok {
			return fmt.Errorf("health check failed")
		}

		return nil
	}
}
