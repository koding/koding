package mount

import (
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type inspectOptions struct {
	filesystem bool
	tree       bool
	sync       bool
}

// NewInspectCommand creates a command that allows to debug existing mount state.
func NewInspectCommand(c *cli.CLI) *cobra.Command {
	opts := &inspectOptions{}

	cmd := &cobra.Command{
		Use:    "inspect <mount-id>",
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
		cli.DaemonRequired, // Deamon service is required.
		cli.ExactArgs(1),   // One argument is required.
	)(c, cmd)

	return cmd
}

func inspectCommand(c *cli.CLI, opts *inspectOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		// Enable sync option when there is none set explicitly. Tree may be too
		// large to show it implicitly.
		if !opts.sync && !opts.tree && !opts.filesystem {
			opts.sync = true
		}

		inspectOpts := &machine.InspectMountOptions{
			Identifier: args[0],
			Sync:       opts.sync,
			Tree:       opts.tree,
			Filesystem: opts.filesystem,
		}

		records, err := machine.InspectMount(inspectOpts)
		if err != nil {
			return err
		}

		cli.PrintJSON(c.Out(), records)
		return nil
	}
}
