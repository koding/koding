package team

import (
	"fmt"
	"koding/kites/kloud/team"
	"koding/klientctl/commands/cli"
	epteam "koding/klientctl/endpoint/team"

	"github.com/spf13/cobra"
)

type useOptions struct{}

// NewUseCommand creates a command that can switch team context.
func NewUseCommand(c *cli.CLI) *cobra.Command {
	opts := &useOptions{}

	cmd := &cobra.Command{
		Use:   "use <team>",
		Short: "Switch team context",
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
		ident := args[0]
		teams, err := epteam.List(&epteam.ListOptions{})
		if err != nil {
			return err
		}

		var team *team.Team
		for _, t := range teams {
			if t.Name == ident || t.Slug == ident {
				team = t
				break
			}
		}

		if team == nil {
			return fmt.Errorf("unable to find %q team", ident)
		}

		epteam.Use(&epteam.Team{
			Name: team.Name,
		})

		fmt.Fprintln(c.Err(), "You are currently logged in to the following team:", team.Name)

		return nil
	}
}
