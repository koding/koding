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
		"[optional args] <alias:remote path> <local folder>",
		fmt.Sprintf(`Mount folder from remote machine to local folder.
    Alias is the local identifer for machine in 'kd list'.

    Local folder can be relative or absolute path, if
    folder doesn't exit, it'll be created.

    By default this uses FUSE to mount remote folders.
    For best I/O performance, especially with commands
    that does a lot of filesystem operations like git,
    use --oneway-sync.`),
	),
	"mount-new": fmtDesc(
		"((<machine-id>|<alias>|<ip>):<remote-path> <local-path> | <command>) [<options>...]",
		fmt.Sprintf(`Mount <remote-path> from remote machine to <local-path>.

   With either <machine-id>, <alias> or <ip> argument, kd machine mount identifies
   requested machine. All of them can by find by running "kd machine list" command"

   <local-path> can be relative or absolute, if the folder does not exit, it will be created.`),
	),
	"ssh": fmtDesc(
		"<alias>", "SSH into the machine.",
	),
	"unmount": fmtDesc(
		"<alias>",
		"Unmount folder which was previously mounted.",
	),
	"umount-new": fmtDesc(
		"<mount-id>",
		"Unmount existing mount with given ID.",
	),
	"remount": fmtDesc(
		"<alias>",
		"Remount machine which was previously mounted using the same settings.",
	),
	"run": fmtDesc(
		"<command> <arguments>",
		fmt.Sprintf(`Run command on remote or local machine depending
    on the location where the command was run.

    All arguments after run are passed to command on
    remote machine.

    Currently only commands that don't require tty/pty
    work on remote machines.`),
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
		"[optional args] <source> <destination>",
		`Copy a file from the source to the destination, either remote to local or local
to remote.

Like with mounting, remote paths are referred to with the
machineName:path/to/file syntax. Example:

  kd cp ./sourceFile apple:destinationFile
  kd cp apple:sourceFile ./destinationFile

`,
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
   kd {{.FullName}}{{if .Description}} {{.Description}}{{end}}{{if .Flags}}

OPTIONS:
   {{range .Flags}}{{.}}
   {{end}}{{end}}
`
}

// fixDescription is a hacky way of dealing with current CLI package. The
// problem is that for codegangsta subcommands .Usage field has value defined
// in .Description field and the real .Usage value is ignored. This makes
// the api invalid when we need to print proper help descriptions.
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
