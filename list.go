package main

import (
	"fmt"
	"log"
	"os"
	"strings"
	"text/tabwriter"

	"github.com/mitchellh/cli"
)

func ListCommandFactory() (cli.Command, error) {
	return &ListCommand{}, nil
}

type ListCommand struct {
}

func (c *ListCommand) Run(_ []string) int {
	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		log.Fatal(err)
	}

	if err = k.Dial(); err != nil {
		log.Fatal(err)
	}

	res, err := k.Tell("remote.list")
	if err != nil {
		log.Fatal(err)
	}

	type kiteInfo struct {
		Ip           string
		VmName       string
		Hostname     string
		MountedPaths []string
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

	return 1
}

func (*ListCommand) Help() string {
	helpText := `
Usage: %s list

	List the available machines.
`
	return fmt.Sprintf(helpText, Name)
}

func (*ListCommand) Synopsis() string {
	return fmt.Sprintf("List the available machines")
}
