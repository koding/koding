package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

// cmdDescriptions is the help text shown to user. Note in addition to adding
// new text here you'll need to update main.go to use the description.
var cmdDescriptions = map[string]string{
	"ssh": fmtDesc("<machine name>", "SSH into the machine."),
	"mount": fmtDesc(
		"<machine name> </path/local/folder>",
		"Mount folder from remote machine to local folder.",
	),
	"unmount": fmtDesc(
		"<machine name>",
		"Unmount folder which was previously mounted.",
	),
}

func init() {
	cli.AppHelpTemplate = `
USAGE:
   {{.Name}} command [command options]

COMMANDS:
   {{range .Commands}}{{join .Names ", "}}{{ "\t" }}{{.Usage}}
   {{end}}
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
