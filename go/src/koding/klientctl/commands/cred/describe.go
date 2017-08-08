package cred

import (
	"fmt"
	"text/tabwriter"

	"koding/kites/kloud/stack"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/credential"

	"github.com/spf13/cobra"
)

type describeOptions struct {
	provider   string
	jsonOutput bool
}

// NewDescribeCommand creates a command that describes credential documents.
func NewDescribeCommand(c *cli.CLI) *cobra.Command {
	opts := &describeOptions{}

	cmd := &cobra.Command{
		Use:   "describe",
		Short: "Describe credential document",
		RunE:  describeCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVarP(&opts.provider, "provider", "p", "", "credential provider")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func describeCommand(c *cli.CLI, opts *describeOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		descs, err := credential.Describe()
		if err != nil {
			return fmt.Errorf("error requesting credential description: %v", err)
		}

		if opts.provider != "" {
			desc, ok := descs[opts.provider]
			if !ok {
				return fmt.Errorf("no description found for %q provider", opts.provider)
			}

			descs = stack.Descriptions{opts.provider: desc}
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), descs.Slice())
			return nil
		}

		printDescs(c, descs.Slice())

		return nil
	}
}

func printDescs(c *cli.CLI, descs []*stack.Description) {
	w := tabwriter.NewWriter(c.Out(), 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "PROVIDER\tATTRIBUTE\tTYPE\tSECRET")

	for _, desc := range descs {
		for _, field := range desc.Credential {
			fmt.Fprintf(w, "%s\t%s\t%s\t%t\n", desc.Provider, field.Name, field.Type, field.Secret)
		}
	}
}
