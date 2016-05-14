package main

import (
	"encoding/json"
	"fmt"
	"koding/klient/remote/req"
	"koding/klientctl/config"
	"koding/klientctl/klient"
	"os"
	"text/tabwriter"
	"time"

	kodinglogging "github.com/koding/logging"

	"github.com/codegangsta/cli"
)

type kiteMounts struct {
	IP         string `json:"ip"`
	RemotePath string `json:"remotePath"`
	LocalPath  string `json:"localPath"`
	MountName  string `json:"mountName"`

	req.MountFolder

	SyncIntervalOpts struct {
		Interval time.Duration `json:"interval"`
	} `json:"syncIntervalOpts"`
}

// MountsCommand returns list of previously mounted folders.
func MountsCommand(c *cli.Context, _ kodinglogging.Logger, _ string) int {
	k, err := klient.CreateKlientWithDefaultOpts()
	if err != nil {
		fmt.Printf("Error connecting to %s: '%s'\n", config.KlientName, err)
		return 1
	}

	if err := k.Dial(); err != nil {
		fmt.Printf("Error connecting to %s: '%s'\n", config.KlientName, err)
		return 1
	}

	res, err := k.Tell("remote.mounts")
	if err != nil {
		fmt.Printf("Error getting list of mounts from %s: '%s'\n", config.KlientName, err)
		return 1
	}

	var mounts []kiteMounts
	res.Unmarshal(&mounts)

	if c.Bool("json") {
		jsonBytes, err := json.MarshalIndent(mounts, "", "  ")
		if err != nil {
			log.Error("Marshalling mounts to json failed. err:%s", err)
			fmt.Println(GenericInternalError)
			return 1
		}

		fmt.Println(string(jsonBytes))
		return 0
	}

	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	fmt.Fprintf(w, "\tNAME\tMACHINE IP\tLOCAL PATH\tREMOTE PATH\n")
	for i, mount := range mounts {
		fmt.Fprintf(w, "  %d.\t%s\t%s\t%s\t%s\n",
			i+1,
			mount.MountName,
			mount.IP,
			mount.LocalPath,
			mount.RemotePath,
		)
	}

	w.Flush()

	return 0
}
