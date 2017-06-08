package cred

import (
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

type initOptions struct {
	provider string
	output   string
	title    string
}

// NewInitCommand creates a command that creates a credential file.
func NewInitCommand(c *cli.CLI) *cobra.Command {
	opts := &initOptions{}

	cmd := &cobra.Command{
		Use:   "init",
		Short: "Create a credential file",
		RunE:  initCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.provider, "provider", "p", "", "credential provider")
	flags.StringVarP(&opts.output, "output", "o", "credential.json", "output filename")
	flags.StringVar(&opts.title, "title", "", "credential title")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func initCommand(c *cli.CLI, opts *initOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		return nil
	}
}
