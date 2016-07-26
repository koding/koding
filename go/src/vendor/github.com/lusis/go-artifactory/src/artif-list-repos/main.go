package main

import (
	"fmt"
	"github.com/olekukonko/tablewriter"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
	"os"

	artifactory "artifactory.v401"
)

var (
	kind = kingpin.Flag("kind", "Types of repos to show").Default("all").Enum("local", "remote", "virtual", "all")
)

func main() {
	kingpin.Parse()
	client := artifactory.NewClientFromEnv()
	data, err := client.GetRepos(*kind)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		table := tablewriter.NewWriter(os.Stdout)
		table.SetHeader([]string{
			"Key",
			"Type",
			"Description",
			"Url",
		})
		for _, r := range data {
			table.Append([]string{
				r.Key,
				r.Rtype,
				r.Description,
				r.Url,
			})
		}
		table.Render()
		os.Exit(0)
	}
}
