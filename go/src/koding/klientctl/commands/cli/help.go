package cli

import (
	"io"
)

// PrintHelp creates cobra handler that prints help for provided function to
// provider writer.
func PrintHelp(w io.Writer) CobraFuncE {
	return ShowHelp(cmd *cobra.Command, args []string) error {
		cmd.SetOutput(w)
		cmd.HelpFunc()(cmd, args)
		return nil
	}
}
