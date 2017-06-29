package stack

import (
	"errors"
	"fmt"
	"io/ioutil"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/stack"

	"github.com/spf13/cobra"
)

type createOptions struct {
	team       string
	title      string
	file       string
	creds      []string
	jsonOutput bool
}

// NewCreateCommand creates a command that can create stacks.
func NewCreateCommand(c *cli.CLI) *cobra.Command {
	opts := &createOptions{}

	cmd := &cobra.Command{
		Use:   "create",
		Short: "Create a new stack",
		RunE:  createCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVar(&opts.team, "team", "", "owner of the stack")
	flags.StringVar(&opts.title, "title", "", "stack title")
	flags.StringVarP(&opts.file, "file", "f", "", "read stack template from a file")
	flags.StringSliceVarP(&opts.creds, "credential", "c", nil, "stack credentials")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func createCommand(c *cli.CLI, opts *createOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		var p []byte
		var err error

		switch opts.file {
		case "":
			return errors.New("no template file was provided")
		case "-":
			p, err = ioutil.ReadAll(c.In())
		default:
			p, err = ioutil.ReadFile(opts.file)
		}

		if err != nil {
			return errors.New("error reading template file: " + err.Error())
		}

		fmt.Fprintln(c.Err(), "Creating stack... ")

		createOpts := &stack.CreateOptions{
			Team:        opts.team,
			Title:       opts.title,
			Credentials: opts.creds,
			Template:    p,
		}

		resp, err := stack.Create(createOpts)
		if err != nil {
			return errors.New("error creating stack: " + err.Error())
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), resp)
			return nil
		}

		fmt.Fprintf(c.Err(), "\nCreatad %q stack with %s ID.\nWaiting for the stack to finish building...\n\n", resp.Title, resp.StackID)

		for e := range kloud.Wait(resp.EventID) {
			if e.Error != nil {
				return fmt.Errorf("building %q stack failed: %s", resp.Title, e.Error)
			}

			fmt.Fprintf(c.Out(), "[%d%%] %s\n", e.Event.Percentage, e.Event.Message)
		}

		return nil
	}
}
