package main

import (
	"fmt"
	"os"
	"text/tabwriter"

	"github.com/codegangsta/cli"
)

type kiteMounts struct {
	Ip         string `json:"ip"`
	RemotePath string `json:"remotePath"`
	LocalPath  string `json:"localPath"`
	MountName  string `json:"mountName"`
}

// MountsCommand returns list of previously mounted folders.
func MountsCommand(c *cli.Context) int {
	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		fmt.Printf("Error connecting to %s: '%s'\n", KlientName, err)
		return 1
	}

	if err := k.Dial(); err != nil {
		fmt.Printf("Error connecting to %s: '%s'\n", KlientName, err)
		return 1
	}

	res, err := k.Tell("remote.mounts")
	if err != nil {
		fmt.Printf("Error getting list of mounts from %s: '%s'\n", KlientName, err)
		return 1
	}

	var mounts []kiteMounts
	res.Unmarshal(&mounts)

	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	fmt.Fprintf(w, "\tNAME\tMACHINE IP\tLOCAL PATH\tREMOTE PATH\n")
	for i, mount := range mounts {
		fmt.Fprintf(w, "  %d.\t%s\t%s\t%s\t%s\n",
			i+1,
			mount.MountName,
			mount.Ip,
			mount.LocalPath,
			mount.RemotePath,
		)
	}

	w.Flush()

	return 0
}
