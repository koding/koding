package main

import (
	"fmt"
	"os"
	"strings"

	artifactory "artifactory.v401"
	"github.com/olekukonko/tablewriter"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
)

var (
	target = kingpin.Arg("target", "permission target to show").Required().String()
)

func main() {
	kingpin.Parse()
	client := artifactory.NewClientFromEnv()
	u, err := client.GetPermissionTargetDetails(*target)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		table := tablewriter.NewWriter(os.Stdout)
		table.SetHeader([]string{"Name", "Includes", "Excludes", "Repositories", "Users", "Groups"})
		row := []string{
			u.Name,
			u.IncludesPattern,
			u.ExcludesPattern,
			strings.Join(u.Repositories, "\n"),
		}
		var users []string
		var groups []string
		for k, v := range u.Principals.Users {
			line := fmt.Sprintf("%s (%s)", k, strings.Join(v, ","))
			users = append(users, line)
		}
		for k, v := range u.Principals.Groups {
			line := fmt.Sprintf("%s (%s)", k, strings.Join(v, ","))
			groups = append(groups, line)
		}
		row = append(row, strings.Join(users, "\n"))
		row = append(row, strings.Join(groups, "\n"))
		table.Append(row)
		table.Render()
		fmt.Println("Legend: m=admin; d=delete; w=deploy; n=annotate; r=read")
		os.Exit(0)
	}
}
