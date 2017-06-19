package log

import (
	"errors"
	"fmt"
	"path/filepath"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type uploadOptions struct{}

// NewUploadCommand creates a command that uploads log files to Koding.
func NewUploadCommand(c *cli.CLI) *cobra.Command {
	opts := &uploadOptions{}

	cmd := &cobra.Command{
		Use:   "upload <file>",
		Short: "Share log file with Koding",
		RunE:  uploadCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.ExactArgs(1), // One argument is accepted.
	)(c, cmd)

	return cmd
}

func uploadCommand(c *cli.CLI, opts *uploadOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		f := &machine.UploadedFile{
			File: args[0],
		}

		if f.File == "" {
			return errors.New("file path is empty or missing")
		}

		if !filepath.IsAbs(f.File) {
			var err error
			f.File, err = filepath.Abs(f.File)
			if err != nil {
				return err
			}
		}

		if err := machine.Upload(f); err != nil {
			return err
		}

		fmt.Fprintln(c.Out(), f.URL)
		return nil
	}
}
