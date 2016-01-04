package main

import (
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/codegangsta/cli"
	"github.com/koding/kite"
)

type kiteInfo struct {
	IP           string
	VMName       string
	Hostname     string
	MachineLabel string
	Mounts       []mountInfo
	Teams        []string

	// TODO: DEPRECATE
	MountedPaths []string
}

type mountInfo struct {
	RemotePath string `json:"remotePath"`
	LocalPath  string `json:"localPath"`
}

// ListCommand returns list of remote machines belonging to user or that can be
// accessed by the user.
func ListCommand(c *cli.Context) int {
	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(
			"Error connecting to %s: '%s'", KlientName, err,
		))
		return 1
	}

	if err := k.Dial(); err != nil {
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(
			"Error connecting to %s: '%s'", KlientName, err,
		))
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

		// For a more clear UX, replace the team name of the default Koding team,
		// with Koding.com
		if team == "Koding" {
			team = "koding.com"
		}

		// TODO: The UX for displaying multiple mounts is not decided, and
		// we only support a single mount for now anyway. So, listing will just default
		// to a single mount.
		var formattedMount string
		if len(info.Mounts) > 0 {
			// TODO: "fishify" the mount paths.
			formattedMount = fmt.Sprintf(
				"%s -> %s",
				FishifyPath(info.Mounts[0].LocalPath),
				FishifyPath(info.Mounts[0].RemotePath),
			)
		}

		fmt.Fprintf(w, "  %d.\t%s\t%s\t%s\t%s\t%s\n",
			i+1, team, info.MachineLabel, info.IP, info.VMName, formattedMount,
		)
	}
	w.Flush()

	return 0
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

// FishifyPath takes a path and returnes a "Fish" like path.
// Example:
//
//     /foo/bar/baz/bat
//
// Becomes:
//
//     /foo/b/b/bat
//
// Note that this is different from Fish, in that it shows the root directory. This
// is done so that a mounted directory that has the same name as the remote directory
// is easier to distinguish.
func FishifyPath(p string) string {
	sep := string(os.PathSeparator)
	l := strings.Split(p, sep)

	first := true
	// premature optimize the end, since we'll need it on every iteration
	last := len(l) - 1

	for i, s := range l {
		if s == "" || i == last {
			continue
		}

		// If this is the first path segment, don't shorten it
		if first {
			first = false
			continue
		}

		l[i] = s[:1]
	}

	return strings.Join(l, sep)
}
