package machine

import (
	"fmt"
	"strings"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type identifiersOptions struct {
	ids        bool
	aliases    bool
	ips        bool
	jsonOutput bool
}

// NewIdentifiersCommand creates a command that displays identifiers of all
// cached machines.
func NewIdentifiersCommand(c *cli.CLI) *cobra.Command {
	opts := &identifiersOptions{}

	cmd := &cobra.Command{
		Use:    "identifiers",
		Short:  "Display machine identifiers",
		RunE:   identifiersCommand(c, opts),
		Hidden: true,
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.ids, "id", true, "machine IDs")
	flags.BoolVar(&opts.aliases, "alias", true, "machine aliases")
	flags.BoolVar(&opts.ips, "ip", true, "machine IP addresses")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func identifiersCommand(c *cli.CLI, opts *identifiersOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		identifiersOpts := &machine.IdentifiersOptions{
			IDs:     opts.ids,
			Aliases: opts.aliases,
			IPs:     opts.ips,
		}

		identifiers, err := machine.Identifiers(identifiersOpts)
		if err != nil {
			return err
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), identifiers)
			return nil
		}

		fmt.Fprintf(c.Out(), "%s\n", strings.Join(identifiers, " "))
		return nil
	}
}
