package main

import (
	"bytes"
	"fmt"
	"github.com/olekukonko/tablewriter"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
	"os"
	"strings"

	artifactory "artifactory.v401"
)

var (
	groupid    = kingpin.Flag("groupid", "groupid coordinate").String()
	artifactid = kingpin.Flag("artifactid", "artifactid coordinate").String()
	version    = kingpin.Flag("version", "version coordinate").String()
	classifier = kingpin.Flag("classifier", "classifier coordinate").String()
	repo       = kingpin.Flag("repo", "repo to search against. can be specified multiple times").Strings()
)

func main() {
	kingpin.Parse()
	client := artifactory.NewClientFromEnv()
	var coords artifactory.Gavc
	if groupid != nil {
		coords.GroupID = *groupid
	}
	if artifactid != nil {
		coords.ArtifactID = *artifactid
	}
	if version != nil {
		coords.Version = *version
	}
	if classifier != nil {
		coords.Classifier = *classifier
	}
	if repo != nil {
		coords.Repos = *repo
	}
	data, err := client.GAVCSearch(&coords)
	if err != nil {
		fmt.Printf("%s\n", err)
		os.Exit(1)
	} else {
		table := tablewriter.NewWriter(os.Stdout)
		table.SetAutoWrapText(false)
		table.SetBorder(false)
		table.SetAlignment(tablewriter.ALIGN_LEFT)

		for _, r := range data {
			var innerBuf bytes.Buffer
			innerTable := tablewriter.NewWriter(&innerBuf)
			innerTable.SetHeader([]string{
				"File",
				"Repo",
				"RemoteUrl",
				"Created",
				"Last Modified",
				"Created By",
				"Modified By",
				"SHA1",
				"MD5",
				"Size",
				"MimeType",
			})
			elems := strings.Split(r.Path, "/")
			fileName := elems[len(elems)-1]
			innerTable.Append([]string{
				fileName,
				r.Repo,
				r.RemoteUrl,
				r.Created,
				r.LastModified,
				r.CreatedBy,
				r.ModifiedBy,
				r.Checksums.SHA1,
				r.Checksums.MD5,
				r.Size,
				r.MimeType,
			})
			innerTable.Render()
			table.Append([]string{
				innerBuf.String(),
			})
			table.Append([]string{
				fmt.Sprintf("Download: %s\n", r.Uri),
			})

		}
		table.Render()
		os.Exit(0)
	}
}
