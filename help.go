package main

import (
	"fmt"

	"github.com/codegangsta/cli"
)

// cmdDescriptions is the help text shown to user. Note in addition to adding
// new text here you'll need to update main.go to use the description.
var cmdDescriptions = map[string]string{
	"install": fmtDesc(
		"<authToken>",
		fmt.Sprintf("Install the %s. sudo is required.", KlientName),
	),
	"mount": fmtDesc(
		"<machine name> </path/local/folder>",
		fmt.Sprintf(`Mount folder from remote machine to local folder.
    Machine name is the local identifer for machine in 'kd list'.
    Local folder can be relative or absolute path.`),
	),
	"ssh": fmtDesc(
		"<machine name>", "SSH into the machine.",
	),
	"unmount": fmtDesc(
		"<machine name>",
		"Unmount folder which was previously mounted.",
	),
	"run": fmtDesc(
		"<machine name>",
		fmt.Sprintf(`Run command on remote machine and return results.
    All arguments after run are passed to command on remove machine.
    TODO: streaming support.`),
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
