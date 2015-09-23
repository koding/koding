package main

import (
	"fmt"
	"os"
	"text/tabwriter"

	"github.com/mitchellh/cli"
)

func MountsCommandFactory() (cli.Command, error) {
	return &MountsCommand{}, nil
}

type MountsCommand struct{}

func (c *MountsCommand) Run(_ []string) int {
	k, err := CreateKlientClient(NewKlientOptions())
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	if err := k.Dial(); err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	res, err := k.Tell("remote.mounts")
	if err != nil {
		// TODO: Print UX friendly err
		fmt.Println("Error:", err)
		return 1
	}

	type kiteMounts struct {
		Ip         string `json:"ip"`
		RemotePath string `json:"remotePath"`
		LocalPath  string `json:"localPath"`
		MountName  string `json:"mountName"`
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

func (*MountsCommand) Help() string {
	helpText := `
Usage: %s mounts

	List the mounted folders on this machine.
`
	return fmt.Sprintf(helpText, Name, KlientName)
}

func (*MountsCommand) Synopsis() string {
	return fmt.Sprintf("List mounted folders on this machine")
}
