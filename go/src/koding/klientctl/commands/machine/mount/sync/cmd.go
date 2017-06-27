package sync

import (
	"os"
	"time"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type options struct {
	timeout time.Duration
	pause   bool
	resume  bool
}

// NewCommand creates a command that manages mount file synchronization.
func NewCommand(c *cli.CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "sync [<mount-id> | <path>]",
		Short: "Manage mounted files synchronization",
		Long: `Wait until all mount synchronization events are processed.

If neither <mount-id> nor <path> are provided, the <path> will be assumed as a
current working directory.
`,
		RunE: command(c, opts),
	}

	// Subcommands.
	cmd.AddCommand(
		NewPauseCommand(c),
		NewResumeCommand(c),
	)

	// Flags.
	flags := cmd.Flags()
	flags.DurationVar(&opts.timeout, "timeout", time.Minute, "max amount of time to wait")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.MaxArgs(1),     // At most one argument is accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) (err error) {
		var ident string
		if len(args) > 0 {
			ident = args[0]
		}

		if ident == "" {
			if ident, err = os.Getwd(); err != nil {
				return err
			}
		}

		syncOpts := &machine.SyncMountOptions{
			Identifier: ident,
			Pause:      opts.pause,
			Resume:     opts.resume,
			Timeout:    opts.timeout,
		}

		return machine.SyncMount(syncOpts)
	}
}
