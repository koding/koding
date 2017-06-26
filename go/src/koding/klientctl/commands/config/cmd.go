package config

import (
	"os"
	"path/filepath"

	konfig "koding/kites/config"
	"koding/klientctl/commands/cli"

	"github.com/spf13/cobra"
)

var (
	// ConfigFolder is folder where config and other related info are stored.
	ConfigFolder string
)

func init() {
	var err error
	if ConfigFolder, err = createFolderAtHome(".config", "koding"); err != nil {
		panic(err)
	}
}

func createFolderAtHome(cf ...string) (string, error) {
	args := []string{konfig.CurrentUser.HomeDir}
	args = append(args, cf...)

	folderName := filepath.Join(args...)
	if err := os.MkdirAll(folderName, 0755); err != nil {
		return "", err
	}

	return folderName, nil
}

// NewCommand creates a command that manages KD configuration.
func NewCommand(c *cli.CLI) *cobra.Command {
	cmd := &cobra.Command{
		Use:   "config",
		Short: "Manage tool configuration",
		RunE:  cli.PrintHelp(c.Err()),
	}

	// Subcommands.
	cmd.AddCommand(
		NewListCommand(c),
		NewResetCommand(c),
		NewSetCommand(c),
		NewShowCommand(c),
		NewUnsetCommand(c),
		NewUseCommand(c),
	)

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}
