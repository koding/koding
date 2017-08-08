package stack

import (
	"fmt"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/remoteapi"
	"koding/klientctl/endpoint/team"
	"koding/remoteapi/models"
	"text/tabwriter"

	"github.com/spf13/cobra"
)

type listOptions struct {
	team       string
	jsonOutput bool
}

// NewListCommand creates a command that can list stacks.
func NewListCommand(c *cli.CLI) *cobra.Command {
	opts := &listOptions{}

	cmd := &cobra.Command{
		Use:     "list",
		Aliases: []string{"ls"},
		Short:   "List all stacks",
		RunE:    listCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVar(&opts.team, "team", "", "limit to team's stacks")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.s
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func listCommand(c *cli.CLI, opts *listOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		f := &remoteapi.Filter{
			Team: opts.team,
		}

		if f.Team == "" {
			f.Team = team.Used().Name
		}

		stacks, err := remoteapi.ListStacks(f)
		if err != nil {
			return err
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), stacks)
			return nil
		}

		printStacks(c, stacks)
		return nil
	}
}

func printStacks(c *cli.CLI, stacks []*models.JComputeStack) {
	w := tabwriter.NewWriter(c.Out(), 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "ID\tTITLE\tOWNER\tTEAM\tSTATE\tREVISION")

	for _, stack := range stacks {
		owner := *stack.OriginID
		if owner != "" {
			if account, err := remoteapi.Account(&models.JAccount{ID: owner}); err == nil && account != nil && account.Profile != nil {
				owner = account.Profile.Nickname
			}
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\t%s\n", stack.ID, str(stack.Title), owner, str(stack.Group), state(stack.Status), stack.StackRevision)
	}
}

func state(status *models.JComputeStackStatus) string {
	if status == nil {
		return "-"
	}
	return status.State
}

func str(s *string) string {
	if s == nil || *s == "" {
		return "-"
	}
	return *s
}
