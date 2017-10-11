package machine

import (
	"fmt"

	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type startOptions struct {
	jsonOutput bool
}

// NewStartCommand creates a command that can start a remote machine.
func NewStartCommand(c *cli.CLI) *cobra.Command {
	opts := &startOptions{}

	cmd := &cobra.Command{
		Use:   "start <machine-identifier>",
		Short: "Start remote machine",
		RunE:  startCommand(c, opts),
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

func startCommand(c *cli.CLI, opts *startOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		event, err := machine.Start(&machine.StartOptions{
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
