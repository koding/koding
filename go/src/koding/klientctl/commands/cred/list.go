package cred

import (
	"fmt"
	"text/tabwriter"

	"koding/kites/kloud/stack"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/credential"

	"github.com/spf13/cobra"
)

type listOptions struct {
	provider   string
	team       string
	jsonOutput bool
}

// NewListCommand creates a command that displays imported stack credentials.
func NewListCommand(c *cli.CLI) *cobra.Command {
	opts := &listOptions{}

	cmd := &cobra.Command{
		Use:     "list",
		Aliases: []string{"ls"},
		Short:   "List imported stack credentials",
		RunE:    listCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.provider, "provider", "p", "", "credential provider")
	flags.StringVar(&opts.team, "team", "", "owner of the credential")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func listCommand(c *cli.CLI, opts *listOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		listOpts := &credential.ListOptions{
			Provider: opts.provider,
			Team:     opts.team,
		}

		creds, err := credential.List(listOpts)
		if err != nil {
			return err
		}

		if len(creds) == 0 {
			return fmt.Errorf("you have no matching credentials attached to your Koding account")
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), creds)
			return nil
		}

		printCreds(c, creds.ToSlice())

		return nil
	}
}

func printCreds(c *cli.CLI, creds []stack.CredentialItem) {
	w := tabwriter.NewWriter(c.Out(), 2, 0, 2, ' ', 0)
	defer w.Flush()

	used := credential.Used()

	fmt.Fprintln(w, "ID\tTITLE\tTEAM\tPROVIDER\tUSED")

	for _, cred := range creds {
		isUsed := "-"

		if ident, ok := used[cred.Provider]; ok && cred.Identifier == ident {
			isUsed = "default"
		}

		fmt.Fprintf(w, "%s\t%s\t%s\t%s\t%s\n", cred.Identifier, cred.Title, cred.Team, cred.Provider, isUsed)
	}
}
