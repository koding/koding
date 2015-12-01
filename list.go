package main

import (
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/codegangsta/cli"
)

type kiteInfo struct {
	IP           string
	VMName       string
	Hostname     string
	MachineLabel string
	MountedPaths []string
	Teams        []string
}

// ListCommand returns list of remote machines belonging to user or that can be
// accessed by the user.
func ListCommand(c *cli.Context) int {
	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		fmt.Printf("Error connecting to %s: '%s'\n", KlientName, err)
		return 1
	}

	if err = k.Dial(); err != nil {
		fmt.Printf("Error connecting to %s: '%s'\n", KlientName, err)
		return 1
	}

	res, err := k.Tell("remote.list")
	if err != nil {
		fmt.Printf("Error fetching list of machines from %s: '%s'\n", KlientName, err)
		return 1
	}

	var infos []kiteInfo
	if err := res.Unmarshal(&infos); err != nil {
		fmt.Printf("Error fetching list of machines from %s: '%s'\n", KlientName, err)
	}

	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	fmt.Fprintf(w, "\tMACHINE NAME\tTEAM\tLABEL\tMACHINE IP\tHOSTNAME\tMOUNTED PATHS\n")
	for i, info := range infos {
		// Join multiple teams into a single identifier
		team := strings.Join(info.Teams, ",")

		if team == "Koding" {
			team = "koding.com"
		}

		fmt.Fprintf(w, "  %d.\t%s\t%s\t%s\t%s\t%s\t%s\n",
			i+1, info.VMName, team, info.MachineLabel, info.IP, info.Hostname, strings.Join(info.MountedPaths, ", "))
	}
	w.Flush()

	return 0
}
