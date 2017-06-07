package cli

import (
	"github.com/spf13/cobra"
)

// CobraFuncE is a shortcut for cobra operation handlers that return errors.
type CobraFuncE func(cmd *cobra.Command, args []string) error

// CobraCmdMiddleware defines function that modifies cobra commands in order
// to add additional functionality to their handlers. All middlewares in this
// package must use only cobra RunE function to not break other components.
type CobraCmdMiddleware func(cli *CLI, rootCmd *cobra.Command)

// MultiCobraCmdMiddleware creates a middleware that applies all provided
// functions with reversed invocation order.
func MultiCobraCmdMiddleware(ccms ...CobraCmdMiddleware) CobraCmdMiddleware {
	return func(cli *CLI, cmd *cobra.Command) {
		for i := len(ccms) - 1; i >= 0; i-- {
			ccms[i](cli, cmd)
		}
	}
}

// ApplyForAll applies the middleware to provided command and all its children.
func ApplyForAll(ccm CobraCmdMiddleware) (ccmRet CobraCmdMiddleware) {
	ccmRet = func(cli *CLI, cmd *cobra.Command) {
		// Apply to current.
		ccm(cli, cmd)

		// Recursively apply to all subcommands.
		for _, subcmd := range cmd.Commands() {
			ccmRet(cli, subcmd)
		}
	}

	return ccmRet
}
