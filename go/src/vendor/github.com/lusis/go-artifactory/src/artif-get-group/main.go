package main

import (
	"fmt"
	"os"
	"strconv"

	artifactory "artifactory.v401"
	"github.com/olekukonko/tablewriter"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
)

var (
	group = kingpin.Arg("group", "group name to show").Required().String()
)

func main() {
	kingpin.Parse()
	client := artifactory.NewClientFromEnv()
	u, err := client.GetGroupDetails(*group)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		table := tablewriter.NewWriter(os.Stdout)
		table.SetHeader([]string{"Name", "Description", "AutoJoin?", "Realm", "Realm Attributes"})
		table.SetAutoWrapText(false)
		table.Append([]string{
			u.Name,
			u.Description,
			strconv.FormatBool(u.AutoJoin),
			u.Realm,
			u.RealmAttributes,
		})
		table.Render()
		os.Exit(0)
	}
}
