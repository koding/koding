package open

import (
	"fmt"
	"io"

	"koding/klientctl/commands/cli"
	"koding/klientctl/klient"
	"koding/klientctl/open"

	"github.com/spf13/cobra"
)

type options struct {
	debug bool
}

// NewCommand creates a command that is used to open provided files in Koding UI.
func NewCommand(c *cli.CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "open <file>...",
		Short: "Open given files in Koding UI",
		Long:  "Open a file on the Koding UI, if the given machine is visible on Koding.",
		RunE:  command(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.debug, "debug", false, "debug mode")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.MinArgs(1),     // At least 1 argument must be provided.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		// Fill our options from the CLI. Any empty options are okay, as
		// the command struct is responsible for verifying valid opts.
		openOpts := open.Options{
			Filepaths: args,
			Debug:     opts.debug || c.IsDebug(),
		}

		init := open.Init{
			Stdout:        c.Out(),
			KlientOptions: klient.NewKlientOptions(),
			Log:           c.Log(),
			Helper: func(w io.Writer) {
				cli.PrintHelp(w)
			},
		}

		openCmd, err := open.NewCommand(init, openOpts)
		if err != nil {
			return fmt.Errorf("unable to create open command")
		}

		if exitCode, err := openCmd.Run(); err != nil {
			return cli.NewError(exitCode, err)
		}

		return nil
	}
}
