package main

import (
	"encoding/json"
	"fmt"
	"io"
	"os"
	"strings"
	"text/tabwriter"
	"time"

	"koding/klientctl/endpoint/machine"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// MachineListCommand returns list of remote machines belonging to the user or
// that can be accessed by her.
func MachineListCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	// List command doesn't support identifiers.
	idents, err := getIdentifiers(c)
	if err != nil {
		return 1, err
	}
	if err := identifiersLimit(idents, 0, 0); err != nil {
		return 1, err
	}

	opts := &machine.ListOptions{
		Log: log.New("machine:list"),
	}

	infos, err := machine.List(opts)
	if err != nil {
		return 1, err
	}

	if c.Bool("json") {
		enc := json.NewEncoder(os.Stdout)
		enc.SetIndent("", "\t")
		enc.Encode(infos)
		return 0, nil
	}

	tabFormatter(os.Stdout, infos)
	return 0, nil
}

// MachineSSHCommand allows to SSH into remote machine.
func MachineSSHCommand(c *cli.Context, log logging.Logger, _ string) (int, error) {
	// SSH command must have only one identifier.
	idents, err := getIdentifiers(c)
	if err != nil {
		return 1, err
	}
	if err := identifiersLimit(idents, 1, 1); err != nil {
		return 1, err
	}

	opts := &machine.SSHOptions{
		Identifier: idents[0],
		Username:   c.String("username"),
		Log:        log.New("machine:ssh"),
	}

	if err := machine.SSH(opts); err != nil {
		return 1, err
	}

	return 0, nil
}

// getIdentifiers extracts identifiers and validate provided arguments.
// TODO(ppknap): other CLI libraries like Cobra have this out of the box.
func getIdentifiers(c *cli.Context) (idents []string, err error) {
	unknown := make([]string, 0)
	for _, arg := range c.Args() {
		if strings.HasPrefix(arg, "-") {
			unknown = append(unknown, arg)
			continue
		}

		idents = append(idents, arg)
	}

	if len(unknown) > 0 {
		plular := ""
		if len(unknown) > 1 {
			plular = "s"
		}

		return nil, fmt.Errorf("unrecognized argument%s: %s", plular, strings.Join(unknown, ", "))
	}

	return idents, nil
}

// identifiersLimit checks if the number of identifiers is in specified limits.
// If max is -1, there are no limits for the maximum number of identifiers.
func identifiersLimit(idents []string, min, max int) error {
	l := len(idents)
	switch {
	case l > 0 && min == 0:
		return fmt.Errorf("this command does not use machine identifiers")
	case l < min:
		return fmt.Errorf("required at least %d machines", min)
	case max != -1 && l > max:
		return fmt.Errorf("too many machines: %s", strings.Join(idents, ", "))
	}

	return nil
}

func tabFormatter(w io.Writer, infos []*machine.Info) {
	now := time.Now()
	tw := tabwriter.NewWriter(w, 2, 0, 2, ' ', 0)

	fmt.Fprintf(tw, "ID\tALIAS\tTEAM\tSTACK\tPROVIDER\tLABEL\tOWNER\tAGE\tIP\tSTATUS\n")
	for _, info := range infos {
		fmt.Fprintf(tw, "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n",
			info.ID,
			info.Alias,
			dashIfEmpty(info.Team),
			dashIfEmpty(info.Stack),
			dashIfEmpty(info.Provider),
			info.Label,
			info.Owner,
			machine.ShortDuration(info.CreatedAt, now),
			info.IP,
			machine.PrettyStatus(info.Status, now),
		)
	}
	tw.Flush()
}

func dashIfEmpty(val string) string {
	if val == "" {
		return "-"
	}

	return val
}
