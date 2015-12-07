package main

import (
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/codegangsta/cli"
	"github.com/koding/kite"
)

// ListCommand returns list of remote machines belonging to user or that can be
// accessed by the user.
func ListCommand(c *cli.Context) int {
	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		fmt.Printf("Error connecting to remote machine: %s\n", err)
		return 1
	}

	if err := k.Dial(); err != nil {
		fmt.Printf("Error connecting to remote machine: %s\n", err)
		return 1
	}

	infos, err := getListOfMachines(k)
	if err != nil {
		fmt.Print(err)
		return 1
	}

	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	fmt.Fprintf(w, "\tTEAM\tLABEL\tIP\tALIAS\tMOUNTED PATHS\n")
	for i, info := range infos {
		// Join multiple teams into a single identifier
		team := strings.Join(info.Teams, ",")

<<<<<<< e70e49264fa0af642e8e0908df7b4996b425570e
		// For a more clear UX, replace the team name of the default Koding team,
		// with Koding.com
		if team == "Koding" {
			team = "koding.com"
		}

		fmt.Fprintf(w, "  %d.\t%s\t%s\t%s\t%s\t%s\t%s\n",
			i+1, info.VMName, team, info.MachineLabel, info.IP, info.Hostname, strings.Join(info.MountedPaths, ", "))
=======
		fmt.Fprintf(w, "  %d.\t%s\t%s\t%s\t%s\t%s\n",
			i+1, team, info.MachineLabel, info.IP, info.VMName, strings.Join(info.MountedPaths, ", "))
>>>>>>> change items in list view
	}
	w.Flush()

	return 0
}

type kiteInfo struct {
	IP           string
	VMName       string
	Hostname     string
	MachineLabel string
	MountedPaths []string
	Teams        []string
}

func getListOfMachines(kite *kite.Client) ([]kiteInfo, error) {
	res, err := kite.Tell("remote.list")
	if err != nil {
		return nil, fmt.Errorf(defaultHealthChecker.CheckAllFailureOrMessagef(
			"Error fetching list of machines from %s: '%s'", KlientName, err,
		))
	}

	var infos []kiteInfo
	if err := res.Unmarshal(&infos); err != nil {
		return nil, fmt.Errorf(defaultHealthChecker.CheckAllFailureOrMessagef(
			"Error fetching list of machines from %s: '%s'", KlientName, err,
		))
	}

	return infos, nil
}
