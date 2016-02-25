package main

import (
	"fmt"
	"os"

	artifactory "artifactory.v401"
	"github.com/olekukonko/tablewriter"
)

func main() {
	client := artifactory.NewClientFromEnv()
	data, err := client.GetGroups()
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		table := tablewriter.NewWriter(os.Stdout)
		table.SetHeader([]string{"Name", "Uri"})
		table.SetAutoWrapText(false)
		for _, u := range data {
			table.Append([]string{u.Name, u.Uri})
		}
		table.Render()
		os.Exit(0)
	}
}
