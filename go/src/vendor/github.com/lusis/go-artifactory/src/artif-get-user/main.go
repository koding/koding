package main

import (
	"fmt"
	"os"
	"strconv"
	"strings"

	artifactory "artifactory.v401"
	"github.com/olekukonko/tablewriter"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
)

var (
	user = kingpin.Arg("user", "User name to show").Required().String()
)

func main() {
	kingpin.Parse()
	client := artifactory.NewClientFromEnv()
	u, err := client.GetUserDetails(*user)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		table := tablewriter.NewWriter(os.Stdout)
		table.SetHeader([]string{"Name", "Email", "Password", "Admin?", "Updatable?", "Last Logged In", "Internal Password Disabled?", "Realm", "Groups"})
		table.SetAutoWrapText(false)
		table.Append([]string{
			u.Name,
			u.Email,
			"<hidden>",
			strconv.FormatBool(u.Admin),
			strconv.FormatBool(u.ProfileUpdatable),
			u.LastLoggedIn,
			strconv.FormatBool(u.InternalPasswordDisabled),
			u.Realm,
			strings.Join(u.Groups, "\n"),
		})
		table.Render()
		os.Exit(0)
	}
}
