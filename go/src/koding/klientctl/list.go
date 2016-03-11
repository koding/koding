package main

import (
	"encoding/json"
	"fmt"
	"koding/klientctl/klient"
	"koding/klientctl/list"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/codegangsta/cli"
	"github.com/koding/kite"
	"github.com/koding/logging"
)

// ListCommand returns list of remote machines belonging to user or that can be
// accessed by the user.
func ListCommand(c *cli.Context, log logging.Logger, _ string) int {
	if len(c.Args()) != 0 {
		cli.ShowCommandHelp(c, "list")
		return 1
	}

	k, err := klient.CreateKlientWithDefaultOpts()
	if err != nil {
		log.Error("Error creating klient client. err:%s", err)
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(GenericInternalError))
		return 1
	}

	if err := k.Dial(); err != nil {
		log.Error("Error dialing klient client. err:%s", err)
		fmt.Println(defaultHealthChecker.CheckAllFailureOrMessagef(GenericInternalError))
		return 1
	}

	infos, err := getListOfMachines(k)
	if err != nil {
		log.Error("Error listing machines. err:%s", err)
		fmt.Println(getListErrRes(err, defaultHealthChecker))
		return 1
	}

	if c.Bool("json") {
		jsonBytes, err := json.MarshalIndent(infos, "", "  ")
		if err != nil {
			log.Error("Marshalling infos to json failed. err:%s", err)
			fmt.Println(GenericInternalError)
			return 1
		}

		fmt.Println(string(jsonBytes))
		return 0
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
				shortenPath(info.Mounts[0].LocalPath),
				shortenPath(info.Mounts[0].RemotePath),
			)
		}

		fmt.Fprintf(w, "  %d.\t%s\t%s\t%s\t%s\t%s\n",
			i+1, team, info.MachineLabel, info.IP, info.VMName, formattedMount,
		)
	}
	w.Flush()

	return 0
}

func getListOfMachines(kite *kite.Client) ([]list.KiteInfo, error) {
	res, err := kite.Tell("remote.list")
	if err != nil {
		return nil, err
	}

	var infos []list.KiteInfo
	if err := res.Unmarshal(&infos); err != nil {
		return nil, err
	}

	return infos, nil
}

// shortenPath takes a path and returnes a "Fish" like path.
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
func shortenPath(p string) string {
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
