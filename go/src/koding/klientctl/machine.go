package main

import (
	"fmt"
	"io"
	"text/tabwriter"
	"time"

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

	fmt.Fprintf(tw, "TEAM\tSTACK\tPROVIDER\tLABEL\tOWNER\tAGE\tIP\tSTATUS\n")
	for _, info := range infos {
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
			info.Team,
			info.Stack,
			info.Provider,
			info.Label,
			info.IP,
			timeToAgo(info.CreatedAt, now),
			info.Owner,
			prettyStatus(info.Status),
		)
	}
	tw.Flush()
}

func prettyStatus(status machine.Status) string {
	now := time.Now()

	if status.State == machine.StatusOnline {
		return fmt.Sprintf("%s (%s)", status.State, timeToAgo(status.ModifiedAt, now))
	}

	timeReasonFmt := "(" + timeToAgo(status.ModifiedAt, now)
	if status.Reason != "" {
		timeReasonFmt += ": " + status.Reason
	} else {
		timeReasonFmt += ")"
	}

	return status.State.String() + " " + timeReasonFmt
}
