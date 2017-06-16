package cli

import (
	"github.com/spf13/cobra"
)

// AliasAnnotation is a cobra command annotation key that stores alternative
// name for the command. This name should be used by middlewares instead of
// command path.
const AliasAnnotation = "command-alias-annotation"

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

// Alias adds alias annotation to command and all its subcommands.
func Alias(cmd *cobra.Command, aliasPath string) *cobra.Command {
	// Do nothing when alias annotation is already set.
	if _, ok := cmd.Annotations[AliasAnnotation]; ok {
		return cmd
	}

	// Include command name to path.
	aliasPath += " " + cmd.Name()

	// Initialize map if it's nil.
	if cmd.Annotations == nil {
		cmd.Annotations = make(map[string]string)
	}

	// Apply to current.
	cmd.Annotations[AliasAnnotation] = aliasPath

	// Recursively apply to all subcommands.
	for _, subcmd := range cmd.Commands() {
		Alias(subcmd, aliasPath)
	}

	return cmd
}
