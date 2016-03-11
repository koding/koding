package main

import (
	"fmt"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
	"os"
	"reflect"
	"strconv"
	"strings"

	artifactory "artifactory.v401"
	"github.com/olekukonko/tablewriter"
)

var (
	repo = kingpin.Arg("repo", "Repo to show").Required().String()
)

func makeBaseRow(b artifactory.RepoConfig) []string {
	s := reflect.ValueOf(b)
	baseRow := []string{
		s.FieldByName("Key").String(),
		s.FieldByName("RClass").String(),
		s.FieldByName("PackageType").String(),
		s.FieldByName("Description").String(),
		s.FieldByName("Notes").String(),
		strconv.FormatBool((s.FieldByName("BlackedOut").Bool())),
		strconv.FormatBool((s.FieldByName("HandleReleases").Bool())),
		strconv.FormatBool((s.FieldByName("HandleSnapshots").Bool())),
		s.FieldByName("ExcludesPattern").String(),
		s.FieldByName("IncludesPattern").String(),
	}
	return baseRow
}

func main() {
	kingpin.Parse()
	client := artifactory.NewClientFromEnv()
	data, err := client.GetRepo(*repo)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		table := tablewriter.NewWriter(os.Stdout)
		table.SetAutoWrapText(false)
		baseHeaders := []string{
			"Key",
			"Type",
			"PackageType",
			"Description",
			"Notes",
			"Blacked Out?",
			"Releases?",
			"Snapshots?",
			"Excludes",
			"Includes",
		}

		// base row data common to all repos
		baseRow := makeBaseRow(data)
		// We have to do this to get to the concrete repo type
		switch data.MimeType() {
		case artifactory.REMOTE_REPO_MIMETYPE:
			d := data.(artifactory.RemoteRepoConfig)
			baseHeaders = append(baseHeaders, "Url")
			table.SetHeader(baseHeaders)
			baseRow = append(baseRow, d.Url)
			table.Append(baseRow)
		case artifactory.LOCAL_REPO_MIMETYPE:
			d := data.(artifactory.LocalRepoConfig)
			baseHeaders = append(baseHeaders, "Layout")
			baseRow = append(baseRow, d.LayoutRef)
			table.SetHeader(baseHeaders)
			table.Append(baseRow)
		case artifactory.VIRTUAL_REPO_MIMETYPE:
			d := data.(artifactory.VirtualRepoConfig)
			baseHeaders = append(baseHeaders, "Repositories")
			baseRow = append(baseRow, strings.Join(d.Repositories, "\n"))
			table.SetHeader(baseHeaders)
			table.Append(baseRow)
		default:
			table.SetHeader(baseHeaders)
			table.Append(baseRow)
		}
		table.Render()
		os.Exit(0)
	}
}
