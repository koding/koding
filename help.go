package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

var cmdDescriptions map[string]string

func init() {
	cmdDescriptions = map[string]string{
		"ssh":   fmtDesc("", "SSH into the machine."),
		"mount": fmtDesc("[vm name] <local folder>", "Mount a remote folder from the given remote machine, to the specified local folder."),
	}

	cli.AppHelpTemplate = `
USAGE:
   {{.Name}} {{if .Flags}}[global options]{{end}}{{if .Commands}} command [command options]{{end}} [arguments...]
   {{if .Version}}
COMMANDS:
   {{range .Commands}}{{join .Names ", "}}{{ "\t" }}{{.Usage}}
   {{end}}{{end}}
`

	cli.CommandHelpTemplate = `USAGE:
    kd {{.FullName}}{{if .Description}} {{.Description}}{{end}}{{if .Flags}}
OPTIONS:
    {{range .Flags}}{{.}}
    {{end}}{{end}}
`
}

func fmtDesc(opts, description string) string {
	return fmt.Sprintf("%s\nDESCRIPTION\n    %s", opts, description)
}
