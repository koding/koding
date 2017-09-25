package config

import (
	"fmt"
	"text/tabwriter"

	"koding/kites/kloud/utils/object"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	"github.com/spf13/cobra"
)

type showOptions struct {
	jsonOutput bool
}

// NewShowCommand creates a command that displays remote machine configuration.
func NewShowCommand(c *cli.CLI) *cobra.Command {
	opts := &showOptions{}

	cmd := &cobra.Command{
		Use:   "show <machine-id>",
		Short: "Show configuration",
		RunE:  showCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func showCommand(c *cli.CLI, opts *showOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		conf, err := machine.Show(&machine.ShowOptions{
			Identifier: args[0],
			AskList:    cli.AskList(c, cmd),
		})
		if err != nil {
			return err
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), conf)
		} else {
			printKeyVal(c, conf)
		}

		return nil
	}
}

var b = &object.Builder{
	Tag:           "json",
	Sep:           ".",
	Recursive:     true,
	FlatStringers: true,
}

// ignoredFields are not displayed on "kd config show" as they are either for
// internal purpose or are deprecated ones.
var ignoredFields = []string{
	"kiteKey",
	"kiteKeyFile",
	"kontrolURL", // deprecated
	"tunnelURL",  // deprecated
	"environment",
	"publicBucketName",
	"publicBucketRegion",
	"tunnelID",
}

func printKeyVal(c *cli.CLI, v interface{}, ignoredFields ...string) {
	w := tabwriter.NewWriter(c.Out(), 2, 0, 2, ' ', 0)
	defer w.Flush()

	fmt.Fprintln(w, "KEY\tVALUE")

	obj := b.Build(v, ignoredFields...)

	for _, key := range obj.Keys() {
		value := obj[key]
		if s := fmt.Sprintf("%v", value); value == nil || s == "" || s == "0" {
			value = "-"
		}
		fmt.Fprintf(w, "%s\t%v\n", key, value)
	}
}
