package cli

import (
	"io"

	"github.com/spf13/cobra"
)

// PrintHelp creates cobra handler that prints help for provided function to
// provider writer.
func PrintHelp(w io.Writer) CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		cmd.SetOutput(w)
		cmd.HelpFunc()(cmd, args)
		return nil
	}
}
