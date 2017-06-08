package stack

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type createOptions struct {
	provider   string
	team       string
	file       string
	creds      []string
	jsonOutput bool
}

// NewCreateCommand creates a command that can create stacks.
func NewCreateCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &createOptions{}

	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create a new stack",
		RunE:  createCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.provider, "provider", "p", "", "stack provider")
	flags.StringVar(&opts.team, "team", "", "owner of the stack")
	flags.StringVarP(&opts.file, "file", "f", "", "read stack template from a file")
	flags.StringSliceVarP(&opts.creds, "credential", "c", nil, "stack credentials")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.NoArgs,                    // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func createCommand(c *cli.CLI, opts *createOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
