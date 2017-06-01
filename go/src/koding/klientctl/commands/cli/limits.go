package cli

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

// NoArgs returns non-nil error when command is called with arguments.
func NoArgs(cmd *cobra.Command, args []string) error {
	if len(args) == 0 {
		return nil
	}

	if cmd.HasSubCommands() {
		return fmt.Errorf("\n" + strings.TrimRight(cmd.UsageString(), "\n"))
	}

	return fmt.Errorf(
		"\"%s\" does not support any arguments.\nSee: '%s --help' for help.\n\nUsage:  %s\n\n%s",
		cmd.CommandPath(),
		cmd.CommandPath(),
		cmd.UseLine(),
		cmd.Short,
	)
}
