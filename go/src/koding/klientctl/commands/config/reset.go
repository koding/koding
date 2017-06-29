package config

import (
	"fmt"

	"koding/klientctl/commands/cli"
	"koding/klientctl/config"
	cfg "koding/klientctl/endpoint/config"

	"github.com/spf13/cobra"
)

type resetOptions struct {
	force bool
}

// NewResetCommand creates a command that resets configuration to the default
// value fetched from Koding.
func NewResetCommand(c *cli.CLI) *cobra.Command {
	opts := &resetOptions{}

	cmd := &cobra.Command{
		Use:   "reset",
		Short: "Reset configuration",
		Long: `This command resets configuration to its default value which is fetched from
Koding service.`,
		RunE: resetCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.force, "force", false, "force retrieving configuration")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func resetCommand(c *cli.CLI, opts *resetOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		resetOpts := &cfg.ResetOpts{
			Force: opts.force,
		}

		if err := cfg.Reset(resetOpts); err != nil {
			return err
		}

		fmt.Fprintf(c.Out(), "Reset %s.\n\nPlease run \"sudo kd restart\" for the new configuration to take effect.\n", config.Konfig.KodingPublic())

		return nil
	}
}
