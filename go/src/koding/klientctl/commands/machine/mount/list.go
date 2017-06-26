package mount

import (
	"fmt"
	"io"
	"strconv"
	"text/tabwriter"

	"koding/klient/machine/mount"
	"koding/klientctl/commands/cli"
	"koding/klientctl/endpoint/machine"

	humanize "github.com/dustin/go-humanize"
	"github.com/spf13/cobra"
)

type listOptions struct {
	filter     string
	jsonOutput bool
}

// NewListCommand creates a command that displays available mounts.
func NewListCommand(c *cli.CLI) *cobra.Command {
	opts := &listOptions{}

	cmd := &cobra.Command{
		Use:     "list",
		Aliases: []string{"ls"},
		Short:   "List available mounts",
		RunE:    listCommand(c, opts),
	}

	// Flags.
	flags := cmd.Flags()
	flags.StringVar(&opts.filter, "filter", "", "limit to specific mount")
	flags.BoolVar(&opts.jsonOutput, "json", false, "output in JSON format")

	// Middlewares.
	cli.MultiCobraCmdMiddleware(
		cli.DaemonRequired, // Deamon service is required.
		cli.NoArgs,         // No custom arguments are accepted.
	)(c, cmd)

	return cmd
}

func listCommand(c *cli.CLI, opts *listOptions) cli.CobraFuncE {
	return func(cmd *cobra.Command, args []string) error {
		listOpts := &machine.ListMountOptions{
			MountID: opts.filter,
		}

		mounts, err := machine.ListMount(listOpts)
		if err != nil {
			return err
		}

		if opts.jsonOutput {
			cli.PrintJSON(c.Out(), mounts)
			return nil
		}

		tabListMountFormatter(c.Out(), mounts)
		return nil
	}
}

func tabListMountFormatter(w io.Writer, mounts map[string][]mount.Info) {
	tw := tabwriter.NewWriter(w, 2, 0, 2, ' ', 0)
	defer tw.Flush()

	// TODO: keep the mounts list sorted.
	fmt.Fprintf(tw, "ID\tMACHINE\tMOUNT\tFILES\tQUEUED\tSYNCING\tSIZE\n")
	for alias, infos := range mounts {
		for _, info := range infos {
			sign := info.Syncing
			fmt.Fprintf(tw, "%s\t%s\t%s\t%s/%s\t%s\t%s\t%s/%s\n",
				info.ID,
				alias,
				info.Mount,
				dashIfError(sign, info.Count),
				dashIfError(sign, info.CountAll),
				dashIfError(sign, info.Queued),
				formatWithNegative(info.Syncing),
				dashIfError(sign, humanize.IBytes(uint64(info.DiskSize))),
				dashIfError(sign, humanize.IBytes(uint64(info.DiskSizeAll))),
			)
		}
	}
}

func formatWithNegative(val int) string {
	switch val {
	case -2:
		return "paused"
	case -1:
		return "error"
	default:
		return strconv.Itoa(val)
	}
}

func dashIfError(sign int, val interface{}) string {
	if sign == -1 {
		return "-"
	}

	return fmt.Sprint(val)
}

func dashIfEmpty(val string) string {
	if val == "" {
		return "-"
	}

	return val
}
