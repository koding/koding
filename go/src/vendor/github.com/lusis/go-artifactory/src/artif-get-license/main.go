package main

import (
	"fmt"
	"os"

	artifactory "artifactory.v401"
	"github.com/olekukonko/tablewriter"
)

func main() {
	client := artifactory.NewClientFromEnv()
	data, err := client.GetLicenseInformation()
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		table := tablewriter.NewWriter(os.Stdout)
		table.SetHeader([]string{"Type", "Expires", "Owner"})
		table.SetAutoWrapText(false)
		table.Append([]string{data.LicenseType, data.ValidThrough, data.LicensedTo})
		table.Render()
		os.Exit(0)
	}
}
