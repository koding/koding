package machine

import (
	"fmt"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type stopOptions struct {
	jsonOutput bool
}

// NewStopCommand creates a command that can stop a remote machine.
func NewStopCommand(c *cli.CLI) *cobra.Command {
	opts := &stopOptions{}

	cmd := &cobra.Command{
		Use:   "stop <machine-identifier>",
		Short: "Stop remote machine",
		RunE:  stopCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.ExactArgs(1),   // One argument is required.
	)(c, cmd)

	return cmd
}

func stopCommand(c *cli.CLI, opts *stopOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		event, err := machine.Stop(&machine.StopOptions{
			Identifier: args[0],
			AskList:    cli.AskList(c, cmd),
		})
		if err != nil {
			return err
		}

		for e := range machine.Wait(event) {
			if e.Error != nil {
				err = e.Error
			}

			if opts.jsonOutput {
				cli.PrintJSON(c.Out(), e)
			} else {
				fmt.Fprintf(c.Out(), "[%d%%] %s\n", e.Event.Percentage, e.Event.Message)
			}
		}

		return err
	}
}
