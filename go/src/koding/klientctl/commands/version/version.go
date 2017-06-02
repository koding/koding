package commands

import (
	"fmt"

	"koding/klientctl/commands/cli"
	"koding/klientctl/config"

	"github.com/spf13/cobra"
)

type versionOptions struct {
	jsonOutput bool
}

// NewVersionCommand creates a command that displays current version of this
// application.
func NewVersionCommand(c *cli.CLI) *cobra.Command {
	opts := versionOptions{}

	cmd := &cobra.Command{
		Use:   "version",
		Short: "Print version information.",
		Long: `Using this command user can check the current and the latest KD version along
with machine's kite query ID.`,
		Args: cli.NoArgs,
		RunE: versionCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	return cmd
}

func versionCommand(c *cli.CLI, opts *versionOptions) cli.CobraFuncE {
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
		fmt.Fprintf(c.Out(), "Latest Version: %s\n", getReadableVersion(v.Latest))
		fmt.Fprintln(c.Out(), "Environment:", v.Environment)
		fmt.Fprintln(c.Out(), "Kite Query ID:", v.KiteID)

		return nil
	}
}

func getReadableVersion(version int) string {
	if version == 0 {
		return "-"
	}
	return fmt.Sprintf("0.1.%d", version)
}
