package main

import (
	"fmt"
	"koding/klientctl/config"

	"github.com/codegangsta/cli"
)

// cmdDescriptions is the help text shown to user. Note in addition to adding
// new text here you'll need to update main.go to use the description.
var cmdDescriptions = map[string]string{
	"install": fmtDesc(
		"<authToken>",
		fmt.Sprintf("Install the %s. sudo is required.", config.KlientName),
	),
	"mount": fmtDesc(
		"<optional args> <alias:remote path> <local folder>",
		fmt.Sprintf("Mount folder from remote machine to local folder.\n\n    Alias is the local identifer for machine in 'kd list'.\n    Local folder can be relative or absolute path, if\n    folder doesn't exit, it'll be created.\n\n    By default this uses FUSE to mount remote folders.\n    For best I/O performance, especially with commands\n    that does a lot of filesystem operations like git, \n    use --oneway-sync."),
	),
	"ssh": fmtDesc(
		"<alias>", "SSH into the machine.",
	),
	"unmount": fmtDesc(
		"<alias>",
		"Unmount folder which was previously mounted.",
	),
	"remount": fmtDesc(
		"<alias>",
		"Remount machine which was previously mounted using the same settings.",
	),
	"run": fmtDesc(
		"<command> <arguments>",
		fmt.Sprintf("Run command on remote or local machine depending\n    on the location where the command was run.\n\n    All arguments after run are passed to command on\n    remote machine.\n\n    Currently only commands that don't require tty/pty\n    work on remote machines."),
	),
	"list": fmtDesc(
		"", "List running machines for user.",
	),
	"restart": fmtDesc(
		"", fmt.Sprintf("Restart the %s.", config.KlientName),
	),
	"stop": fmtDesc(
		"", fmt.Sprintf("Stop the %s.", config.KlientName),
	),
	"start": fmtDesc(
		"", fmt.Sprintf("Start the %s.", config.KlientName),
	),
	"status": fmtDesc(
		"", fmt.Sprintf("Check status of the %s.", config.KlientName),
	),
	"uninstall": fmtDesc(
		"", fmt.Sprintf("Uninstall the %s.", config.KlientName),
	),
	"update": fmtDesc(
		"", fmt.Sprintf("Update %s to latest version.", config.KlientName),
	),
	"version": fmtDesc(
		"", fmt.Sprintf("Display version information of the %s.", config.KlientName),
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
