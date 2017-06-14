package cli

import (
	"fmt"
	"strings"

	"github.com/spf13/cobra"
)

// TODO: Deprecate the middlewares when cobra/pull/284 is merged.

// NoArgs returns non-nil error when command is called with non zero arguments.
func NoArgs(cli *CLI, rootCmd *cobra.Command) {
	tail := rootCmd.PreRunE
	rootCmd.PreRunE = func(cmd *cobra.Command, args []string) error {
		if err := noArgs(cmd, args); err != nil {
			return err
		}

		if tail != nil {
			return tail(cmd, args)
		}

		return nil
	}
}

func noArgs(cmd *cobra.Command, args []string) error {
	if len(args) == 0 {
		return nil
	}

	if cmd.HasSubCommands() {
		return fmt.Errorf("unknown command %q for %q", strings.Join(args, " "), cmd.Name())
	}

	return fmt.Errorf("%q does not support any arguments", cmd.CommandPath())
}

// ExactArgs returns nil error only if command is called with exactly n arguments.
func ExactArgs(n int) CobraCmdMiddleware {
	return func(cli *CLI, rootCmd *cobra.Command) {
		tail := rootCmd.PreRunE
		rootCmd.PreRunE = func(cmd *cobra.Command, args []string) error {
			if err := exactArgs(n, cmd, args); err != nil {
				return err
			}

			if tail != nil {
				return tail(cmd, args)
			}

			return nil
		}
	}
}

func exactArgs(n int, cmd *cobra.Command, args []string) error {
	if len(args) == n {
		return nil
	}

	return fmt.Errorf("%q requires exactly %d argument(s)", cmd.CommandPath(), n)
}

// MaxArgs returns nil error only if command is called with 0 to max
// arguments inclusively.
func MaxArgs(max int) CobraCmdMiddleware {
	return func(cli *CLI, rootCmd *cobra.Command) {
		tail := rootCmd.PreRunE
		rootCmd.PreRunE = func(cmd *cobra.Command, args []string) error {
			if err := maxArgs(max, cmd, args); err != nil {
				return err
			}

			if tail != nil {
				return tail(cmd, args)
			}

			return nil
		}
	}
}

func maxArgs(max int, cmd *cobra.Command, args []string) error {
	if len(args) <= max {
		return nil
	}

	return fmt.Errorf("%q requires at most %d argument(s)", cmd.CommandPath(), max)
}

// MinArgs returns nil error only if command is called with at least min
// arguments inclusively.
func MinArgs(min int) CobraCmdMiddleware {
	return func(cli *CLI, rootCmd *cobra.Command) {
		tail := rootCmd.PreRunE
		rootCmd.PreRunE = func(cmd *cobra.Command, args []string) error {
			if err := minArgs(min, cmd, args); err != nil {
				return err
			}

			if tail != nil {
				return tail(cmd, args)
			}

			return nil
		}
	}
}

func minArgs(min int, cmd *cobra.Command, args []string) error {
	if len(args) >= min {
		return nil
	}

	return fmt.Errorf("%q requires at least %d argument(s)", cmd.CommandPath(), min)
}

// RangeArgs returns nil error only if command is called with number of
// arguments between specified range inclusively.
func RangeArgs(min, max int) CobraCmdMiddleware {
	return func(cli *CLI, rootCmd *cobra.Command) {
		tail := rootCmd.PreRunE
		rootCmd.PreRunE = func(cmd *cobra.Command, args []string) error {
			if err := rangeArgs(min, max, cmd, args); err != nil {
				return err
			}

			if tail != nil {
				return tail(cmd, args)
			}

			return nil
		}
	}
}

func rangeArgs(min, max int, cmd *cobra.Command, args []string) error {
	if len(args) >= min && len(args) <= max {
		return nil
	}

	return fmt.Errorf("%q requires at least %d and at most %d argument(s)", cmd.CommandPath(), min, max)
}
