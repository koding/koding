package version

import (
	"fmt"

	"koding/klientctl/commands/cli"
	"koding/klientctl/config"

	"github.com/spf13/cobra"
)

type options struct {
	jsonOutput bool
}

// NewCommand creates a command that displays current version of this application.
func NewCommand(c *cli.CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "version",
		Short: "Print version information",
		Long: `Using this command user can check the current and the latest KD version along
with machine's kite query ID.`,
		RunE: command(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		v := struct {
			Installed   int    `json:"installed"`
			Latest      int    `json:"latest"`
			Environment string `json:"environment"`
			KiteID      string `json:"kiteID"`
		}{
			Installed:   config.VersionNum(),
			Environment: config.Environment,
			KiteID:      config.Konfig.KiteConfig().Id,
		}

		v.Latest, _ = config.LatestKDVersionNum()
		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), v)
			return nil
		}

		fmt.Fprintf(c.Out(), "Installed Version: %s\n", getReadableVersion(v.Installed))

		if v.Latest != 0 {
			fmt.Fprintf(c.Out(), "Latest Version: %s\n", getReadableVersion(v.Latest))
		}

		fmt.Fprintln(c.Out(), "Environment:", v.Environment)
		fmt.Fprintln(c.Out(), "Kite Query ID:", v.KiteID)

		return nil
	}
}

func getReadableVersion(version int) string {
	if version == 0 {
		return "unknown"
	}
	return fmt.Sprintf("0.1.%d", version)
}
