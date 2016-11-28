package main

import (
	"fmt"
	"io"
	"os"
	"text/tabwriter"
	"time"

	kmachine "koding/klient/machine"
	"koding/klientctl/machine"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// MachineListCommand returns list of remote machines belonging to the user or
// that can be accessed by her.
func MachineListCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	opts := &machine.ListOptions{
		Log: log.New("machine:list"),
	}

	infos, err := machine.List(opts)
	if err != nil {
		return 1, err
	}

	tabFormatter(os.Stdout, infos)
	return 0, nil
}

func tabFormatter(w io.Writer, infos []*machine.Info) {
	now := time.Now()
	tw := tabwriter.NewWriter(w, 2, 0, 2, ' ', 0)

	fmt.Fprintf(tw, "ID\tALIAS\tTEAM\tSTACK\tPROVIDER\tLABEL\tOWNER\tAGE\tIP\tSTATUS\n")
	for _, info := range infos {
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
			info.ID,
			info.Alias,
			info.Team,
			info.Stack,
			info.Provider,
			info.Label,
			info.Owner,
			timeToAgo(info.CreatedAt, now),
			info.IP,
			prettyStatus(info.Status),
		)
	}
	tw.Flush()
}

func prettyStatus(status kmachine.Status) string {
	now := time.Now()

	if status.State == kmachine.StateOnline {
		return fmt.Sprintf("%s (%s)", status.State, timeToAgo(status.Since, now))
	}

	timeReasonFmt := timeToAgo(status.Since, now)
	if status.Reason != "" {
		timeReasonFmt += ": " + status.Reason
	}

	return fmt.Sprintf("%s (%s)", status.State, timeReasonFmt)
}
