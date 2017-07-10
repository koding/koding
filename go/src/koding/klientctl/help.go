package main

import (
	"fmt"
	"koding/klientctl/config"

	cli "gopkg.in/urfave/cli.v1"
)

// cmdDescriptions is the help text shown to user. Note in addition to adding
// new text here you'll need to update main.go to use the description.
var cmdDescriptions = map[string]string{
	"install": fmtDesc(
		"<authToken>",
		fmt.Sprintf("Install the %s. sudo is required.", config.KlientName),
	),
	"mount": fmtDesc(
		"(<machine-identifier>:<remote-path> <local-path> | <command>) [<options>...]",
		`Mount <remote-path> from remote machine to <local-path>.

   With <machine-identifier> argument, kd machine mount identifies requested machine.
   Either machine ID, machine alias or IP can be used as identifier and all of them
   can by obtained by running "kd machine list" command.

   <local-path> can be relative or absolute, if the folder does not exit, it will be created.`,
	),
	"mount-sync": fmtDesc(
		"[<mount-id> | <path> | <command>] [<options>...]",
		`Wait or disable mount synchronization for a given mount.

   If neither <mount-id> nor <path> is provided, the <path> will be assumed as current
   working directory.

   Pause command does not stop currently running synchronization jobs.`,
	),
	"exec": fmtDesc(
		"(<local-mount-path> | @<machine-id>) <command> [<args>...]",
		`Run <command> on a remote machine specified by either @<machine-id> or <local-mount-path>.

   If <local-mount-path> is provided, kd is going to look up a remote machine
   by reading the remote source of the mount. The mount must be active and
   the remote end on-line.

   In order to run a <command> on a remote machine that has no local mounts,
   use @<machine-id> argument instead.`,
	),
	"ssh": fmtDesc(
		"<alias>", "SSH into the machine.",
	),
	"umount": fmtDesc(
		"(<mount-id> | <mount-path>)...",
		"Unmount existing mounts.",
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
	"autocompletion": fmtDesc(
		"[optional args] <shellname>",
		`Install autocompletion files for the given shell, to enable
    autocompletion with kd`,
	),
	"sync": fmtDesc(
		"[optional args] <machineName> <remote-to-local|local-to-remote>",
		"Manually sync a OneWaySync Mount, in either direction.",
	),
	"cp": fmtDesc(
		"[<machine-identifier>:]<source-path> [<machine-identifier>:]<destination-path>",
		`Copy file(s) from <source-path> to the <destination-path>.

   Either <source-path> or <destination-path> must contain <machine-identifier>. Thus,
   it's not possible to copy files between two remote machines.

   If <destination-path> doesn't exist, it will be created.`,
	),
	"open": fmtDesc(
		"[optional args] <file1> [file2] [file3]",
		`Open a file on the Koding UI, if the given machine is visible on Koding.

`,
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
   kd {{.FullName}}{{if .Description}} {{.Description}}{{else if .Usage}} - {{.Usage}}{{end}}{{if .Flags}}

OPTIONS:
   {{range .Flags}}{{.}}
   {{end}}{{end}}
`

	cli.SubcommandHelpTemplate = `NAME:
   {{.HelpName}} - {{.Usage}}

USAGE:
   {{.HelpName}} command{{if .VisibleFlags}} [command options]{{end}} {{if .ArgsUsage}}{{.ArgsUsage}}{{else}}[arguments...]{{end}}

COMMANDS:{{range .VisibleCategories}}{{if .Name}}
   {{.Name}}:{{end}}{{range .VisibleCommands}}
   {{join .Names ", "}}{{"\t"}}{{.Usage}}{{end}}
{{end}}{{if .VisibleFlags}}
OPTIONS:
   {{range .VisibleFlags}}{{.}}
   {{end}}{{end}}
`
}

// fixDescription is a hacky way of dealing with current CLI package. The
// problem is that for codegangsta subcommands .Usage field holds value defined
// in .Description field and the real .Usage value is ignored. This makes
// the CLI API invalid when we need to print proper help description.
func fixDescription(usage string) func() {
	tmp := cli.SubcommandHelpTemplate

	cli.SubcommandHelpTemplate = `NAME:
   {{.HelpName}} - ` + usage + `

USAGE:
   {{.HelpName}} {{.Usage}}
COMMANDS:{{range .VisibleCategories}}{{if .Name}}
   {{.Name}}:{{end}}{{range .VisibleCommands}}
   {{join .Names ", "}}{{"\t"}}{{.Usage}}{{end}}
{{end}}{{if .VisibleFlags}}
OPTIONS:
   {{range .VisibleFlags}}{{.}}
   {{end}}{{end}}
`

	return func() {
		cli.SubcommandHelpTemplate = tmp
	}
}

func fmtDesc(opts, description string) string {
	return fmt.Sprintf("%s\n\nDESCRIPTION\n   %s\n", opts, description)
}
