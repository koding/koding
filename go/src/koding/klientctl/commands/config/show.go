package config

import (
	"fmt"
	"text/tabwriter"

	"koding/kites/kloud/utils/object"
	"koding/klient/storage"
	"koding/klientctl/commands/cli"
	"koding/klientctl/config"
	cfg "koding/klientctl/endpoint/config"

	"github.com/spf13/cobra"
)

type showOptions struct {
	defaults   bool
	jsonOutput bool
}

// NewShowCommand creates a command that displays configurations.
func NewShowCommand(c *cli.CLI) *cobra.Command {
	opts := &showOptions{}

	cmd := &cobra.Command{
		Use:   "show",
		Short: "Show configuration",
		RunE:  showCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.BoolVar(&opts.defaults, "defaults", false, "include default configuration")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.NoArgs, // No custom arguments are accepted.
	)(c, cmd)

	return cmd
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

func showCommand(c *cli.CLI, opts *showOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		used := config.Konfig

		if !opts.defaults {
			k, err := cfg.Used()
			if err != nil && err != storage.ErrKeyNotFound {
				return err
			}
			if err == nil {
				used = k
			}
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), used)
			return nil
		}

		printKeyVal(c, used, ignoredFields...)

		return nil
	}
}

var b = &object.Builder{
	Tag:           "json",
	Sep:           ".",
	Recursive:     true,
	FlatStringers: true,
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
