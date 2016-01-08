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
		"<alias> <local folder>",
		fmt.Sprintf(`Mount folder from remote machine to local folder.
    Alias is the local identifer for machine in 'kd list'.
    Local folder can be relative or absolute path, if
    folder doesn't exit, it'll be created.`),
	),
	"ssh": fmtDesc(
		"<alias>", "SSH into the machine.",
	),
	"unmount": fmtDesc(
		"<alias>",
		"Unmount folder which was previously mounted.",
	),
	"run": fmtDesc(
		"<command> <arguments>",
		fmt.Sprintf(`Run command on remote or local machine depending on the location
    where the command was run. If command was run on mount, it runs
    the command on remote machine and returns the results. If command
    was run on local, it runs the command on local machine and returns
    the results. Currently only commands that don't require tty/pty work
    on remote machines.
    All arguments after run are passed to command on remote machine.`),
	),
	"restart": fmtDesc(
		"", fmt.Sprintf("Restart the %s.", KlientName),
	),
	"stop": fmtDesc(
		"", fmt.Sprintf("Stop the %s.", KlientName),
	),
	"start": fmtDesc(
		"", fmt.Sprintf("Start the %s.", KlientName),
	),
	"status": fmtDesc(
		"", fmt.Sprintf("Check status of the %s.", KlientName),
	),
	"uninstall": fmtDesc(
		"", fmt.Sprintf("Uninstall the %s.", KlientName),
	),
	"update": fmtDesc(
		"", fmt.Sprintf("Update %s to latest version.", KlientName),
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
