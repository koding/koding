package main

import (
	"fmt"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/codegangsta/cli"
)

func ListCommand(c *cli.Context) int {
	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		fmt.Printf("Error connecting to remote VM: '%s'\n", err)
		return 1
	}

	if err = k.Dial(); err != nil {
		fmt.Printf("Error connecting to remote VM: '%s'\n", err)
		return 1
	}

	res, err := k.Tell("remote.list")
	if err != nil {
		fmt.Printf("Error fetching list of VMs from: '%s'\n", KlientName, err)
		return 1
	}

	var infos []kiteInfo
	res.Unmarshal(&infos)

	w := tabwriter.NewWriter(os.Stdout, 2, 0, 2, ' ', 0)
	fmt.Fprintf(w, "\tNAME\tMACHINE IP\tHOSTNAME\tMOUNTED PATHS\n")
	for i, info := range infos {
		fmt.Fprintf(w, "  %d.\t%s\t%s\t%s\t%s\n",
			i+1, info.VmName, info.Ip, info.Hostname, strings.Join(info.MountedPaths, ", "))
	}
	w.Flush()

	return 0
}

type kiteInfo struct {
	Ip           string
	VmName       string
	Hostname     string
	MountedPaths []string
}
