package config

import (
	"fmt"

	"koding/kites/config/configstore"
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type useOptions struct{}

// NewUseCommand creates a command that can change currently active configuration.
func NewUseCommand(c *cli.CLI) *cobra.Command {
	opts := &useOptions{}

	cmd := &cobra.Command{
		Use:   "use <config-id>",
		Short: "Change active configuration",
		RunE:  useCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.ExactArgs(1), // One argument is accepted.
	)(c, cmd)

	return cmd
}

func useCommand(c *cli.CLI, opts *useOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		arg := args[0]

		k, ok := configstore.List()[arg]
		if !ok {
			fmt.Fprintf(c.Err(), "Configuration %q was not found. Please use \"kd config list"+
				"\" to list available configurations.\n", arg)
			return nil
		}

		if err := configstore.Use(k); err != nil {
			return fmt.Errorf("error switching configuration: %v", err)
		}

		fmt.Fprintf(c.Out(), "Switched to %s.\n\nPlease run \"sudo kd restart\" for the new configuration to take effect.\n", k.KodingPublic())

		return nil
	}
}
