package mount

import (
	"fmt"
	"strings"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type identifiersOptions struct {
	mountIds   bool
	basePaths  bool
	jsonOutput bool
}

// NewIdentifiersCommand creates a command that displays identifiers of all
// cached mounts.
func NewIdentifiersCommand(c *cli.CLI) *cobra.Command {
	opts := &identifiersOptions{}

	cmd := &cobra.Command{
		Use:    "identifiers",
		Short:  "Display mount identifiers",
		RunE:   identifiersCommand(c, opts),
		Hidden: true,
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.mountIds, "mount-id", true, "mount IDs")
	flags.BoolVar(&opts.basePaths, "base-path", true, "mount base paths")
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
		identifiersOpts := &machine.MountIdentifiersOptions{
			MountIds:  opts.mountIds,
			BasePaths: opts.basePaths,
		}

		identifiers, err := machine.MountIdentifiers(identifiersOpts)
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
