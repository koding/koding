package machine

import (
	"fmt"
	"path/filepath"
	"strings"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type cpOptions struct{}

// NewCpCommand creates a command that allows to copy files between machines.
func NewCpCommand(c *cli.CLI) *cobra.Command {
	opts := &cpOptions{}

	cmd := &cobra.Command{
		Use:                "cp",
		Short:              "Copy file(s) between machines",
		DisableFlagParsing: true,
		RunE:               cpCommand(c, opts),
	}

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.ExactArgs(2),   // Two arguments are required.
	)(c, cmd)

	return cmd
}

func cpCommand(c *cli.CLI, opts *cpOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		download, ident, source, dest, err := cpAddress(args)
		if err != nil {
			return err
		}

		cpOpts := &machine.CpOptions{
			Download:        download,
			Identifier:      ident,
			SourcePath:      source,
			DestinationPath: dest,
		}

		return machine.Cp(cpOpts)
	}
}

// cpAddress checks if provided identifiers are valid from the cp command
// perspective. The identifiers should satisfy the following format:
//
//  [(ID|Alias|IP):]source_directory/path [(ID|Alias|IP):]remote_directory/path
//
func cpAddress(idents []string) (download bool, ident, source, dest string, err error) {
	if len(idents) != 2 {
		err = fmt.Errorf("invalid number of arguments: %s", strings.Join(idents, ", "))
		return
	}

	srcs, dsts := strings.Split(idents[0], ":"), strings.Split(idents[1], ":")
	switch srcl, dstl := len(srcs), len(dsts); {
	case srcl == 1 && dstl == 1 || srcl >= 2 && dstl >= 2:
		err = fmt.Errorf("invalid address format: %s %s", idents[0], idents[1])
		return
	case srcl == 2 && dstl == 1:
		if dest, err = filepath.Abs(dsts[0]); err != nil {
			err = fmt.Errorf("invalid format of local path %q: %s", dsts[0], err)
			return
		}
		ident, source = srcs[0], srcs[1]
		download = true
	case srcl == 1 && dstl == 2: // upload.
		if source, err = filepath.Abs(srcs[0]); err != nil {
			err = fmt.Errorf("invalid format of local path %q: %s", srcs[0], err)
			return
		}
		ident, dest = dsts[0], dsts[1]
	}

	return
}
