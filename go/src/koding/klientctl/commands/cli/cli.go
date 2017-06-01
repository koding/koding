package cli

import (
	"github.com/spf13/cobra"
)

// CobraFuncE is a shortcut for cobra operation handlers that retturn errors.
type CobraFuncE func(cmd *cobra.Command, args []string) error

// UnionCobraFuncE creates a new cobra handler which calls first and next
// functions respectively.
func UnionCobraFuncE(first, next ...CobraFuncE) CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		for _, f := range append([]CobraFuncE{first}, next...) {
			if err := f(cmd, args); err != nil {
				return err
			}
		}

		return nil
	}
}

type CLI struct {
}
