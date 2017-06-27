package team

import (
	"fmt"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/team"

	"github.com/spf13/cobra"
)

type showOptions struct {
	jsonOutput bool
}

// NewShowCommand creates a command that displays currently used team.
func NewShowCommand(c *cli.CLI) *cobra.Command {
	opts := &showOptions{}

	cmd := &cobra.Command{
		Use:   "show",
		Short: "Show currently used team",
		RunE:  showCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func showCommand(c *cli.CLI, opts *showOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		t := team.Used()

		if err := t.Valid(); err != nil {
			fmt.Fprintln(c.Err(), `You are not currently logged in to any team. Please log in first with "kd auth login".`)
			return err
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), t)
		} else {
			fmt.Fprintln(c.Err(), "You are currently logged in to the following team:", t.Name)
		}

		return nil
	}
}
