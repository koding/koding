package cred

import (
	"errors"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/credential"

	"github.com/spf13/cobra"
)

type useOptions struct{}

// NewUseCommand creates a command that can change default credential per
// provider.
func NewUseCommand(c *cli.CLI) *cobra.Command {
	opts := &useOptions{}

	cmd := &cobra.Command{
		Use:   "use <credential-id>",
		Short: "Change default credential per provider",
		RunE:  useCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.ExactArgs(1),   // One argument is accepted.
	)(c, cmd)

	return cmd
}

func useCommand(c *cli.CLI, opts *useOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		if err := credential.Use(args[0]); err != nil {
			return errors.New("error changing default credential: " + err.Error())
		}

		return nil
	}
}
