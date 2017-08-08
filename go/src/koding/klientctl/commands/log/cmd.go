package log

import (
	"fmt"
	"io"

	"koding/klientctl/commands/cli"
	"koding/klientctl/logcmd"

	"github.com/spf13/cobra"
)

type options struct {
	debug         bool
	noKdLog       bool
	noKlientLog   bool
	kdLogFile     string
	klientLogFile string
	lines         int
}

// NewCommand creates a command that displays logs.
func NewCommand(c *cli.CLI) *cobra.Command {
	opts := &options{}

	cmd := &cobra.Command{
		Use:   "log",
		Short: "Display logs",
		RunE:  command(c, opts),
	}

	// Subcommands.
	cmd.AddCommand(
		NewUploadCommand(c),
	)

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.debug, "debug", false, "debug mode")
	flags.Lookup("debug").Hidden = true
	flags.BoolVar(&opts.noKdLog, "no-kd-log", false, "do not show kd logs")
	flags.BoolVar(&opts.noKlientLog, "no-klient-log", false, "do not show klient logs")
	flags.StringVar(&opts.kdLogFile, "kd-log-file", "", "kd log file")
	flags.StringVar(&opts.klientLogFile, "klient-log-file", "", "klient log file")
	flags.IntVarP(&opts.lines, "lines", "n", 0, "number of lines to display")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func command(c *cli.CLI, opts *options) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		// Fill our log options from the CLI. Any empty options are okay, as
		// the command struct is responsible for verifying valid opts.
		logOpts := logcmd.Options{
			Debug:             opts.debug || c.IsDebug(),
			KdLog:             !opts.noKdLog,
			KlientLog:         !opts.noKlientLog,
			KdLogLocation:     opts.kdLogFile,
			KlientLogLocation: opts.klientLogFile,
			Lines:             opts.lines,
		}

		init := logcmd.Init{
			Stdout: c.Out(),
			Log:    c.Log(),
			Helper: func(w io.Writer) {
				cli.PrintHelp(w)
			},
		}

		logCmd, err := logcmd.NewCommand(init, logOpts)
		if err != nil {
			return fmt.Errorf("unable to create log command")
		}

		if exitCode, err := logCmd.Run(); err != nil {
			return cli.NewError(exitCode, err)
		}

		return nil
	}
}
