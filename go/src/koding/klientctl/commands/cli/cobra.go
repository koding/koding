package cli

import (
	"github.com/spf13/cobra"
)

// CobraCmdMiddleware defines function that modifies cobra commands in order
// to add additional functionality to their handlers. All middlewares in this
// package must use only cobra RunE function to not break other components.
type CobraCmdMiddleware func(cli *CLI, cmd *cobra.Command)

// MultiCobraCmdMiddleware creates a middleware that applies all provided
// functions preserving invocation order.
func MultiCobraCmdMiddleware(ccms ...CobraCmdMiddleware) CobraCmdMiddleware {
	return func(cli *CLI, cmd *cobra.Command) {
		for _, ccm := range ccms {
			ccm(cli, cmd)
		}
	}
}
