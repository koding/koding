package main

import (
	"fmt"
	kingpin "gopkg.in/alecthomas/kingpin.v2"
	"os"

	artifactory "artifactory.v401"
)

var (
	repo     = kingpin.Arg("repo", "repository key for upload").Required().String()
	file     = kingpin.Arg("filename", "file to upload").Required().ExistingFile()
	path     = kingpin.Arg("path", "path for deployed file").String()
	property = kingpin.Flag("property", "properties for the upload").StringMap()
	silent   = kingpin.Flag("silent", "supress output").Bool()
)

func main() {
	kingpin.Parse()
	client := artifactory.NewClientFromEnv()

	i, err := client.DeployArtifact(*repo, *file, *path, *property)
	if err != nil {
		if *silent != true {
			fmt.Printf("%s\n", err)
		}
		os.Exit(1)
	} else {
		if *silent != true {
			fmt.Printf("%s\n", i.URI)
		}
		os.Exit(0)
	}
}
