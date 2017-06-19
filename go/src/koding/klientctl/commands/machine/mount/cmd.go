package mount

import (
	"fmt"
	"path/filepath"
	"strings"

	"koding/klientctl/commands/cli"
	msync "koding/klientctl/commands/machine/mount/sync"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type options struct{}

// NewCommand creates a command that allows to create mounts and manage their
// properties.
func NewCommand(c *cli.CLI, aliasPath ...string) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:     "mount",
		Aliases: []string{"m"},
		Short:   "Mount remote directory",
		RunE:    command(c, opts),
	}

	// Subcommands.
	cmd.AddCommand(
		NewInspectCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		NewListCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
		msync.NewCommand(c, cli.ExtendAlias(cmd, aliasPath)...),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired,            // Deamon service is required.
		cli.WithMetrics(aliasPath...), // Gather statistics for this command.
		cli.RangeArgs(1, 2),           // One or two arguments are required.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		ident, remotePath, path, err := mountExport(args)
		if err != nil {
			return err
		}

		opts := &machine.MountOptions{
			Identifier: ident,
			Path:       path,
			RemotePath: remotePath,
		}

		if err := machine.Mount(opts); err != nil {
			return err
		}

		// Best-effort attempt of making the remote vm do not
		// turn off after 1h.
		_ = machine.Set(ident, "alwaysOn", "true")

		return nil
	}
}

// mountExport checks if provided identifiers are valid from the mount
// perspective. The identifiers should satisfy the following format:
//
//   (ID|Alias|IP)[:remote_directory/path] [local_directory/path]
//
func mountExport(idents []string) (ident, remotePath, path string, err error) {
	if len(idents) != 1 && len(idents) != 2 {
		return "", "", "", fmt.Errorf("invalid number of arguments: %s", strings.Join(idents, ", "))
	}

	ident = idents[0]

	if i := strings.IndexRune(ident, ':'); i != -1 {
		ident, remotePath = ident[:i], ident[i+1:]
	}

	if len(idents) == 2 {
		if path, err = filepath.Abs(idents[1]); err != nil {
			return "", "", "", fmt.Errorf("invalid format of local path %q: %s", idents[1], err)
		}
	}

	return
}
