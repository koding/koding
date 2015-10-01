package main

import "github.com/codegangsta/cli"

func init() {
	cli.AppHelpTemplate = `
USAGE:
   {{.Name}} {{if .Flags}}[global options]{{end}}{{if .Commands}} command [command options]{{end}} [arguments...]
   {{if .Version}}
COMMANDS:
   {{range .Commands}}{{join .Names ", "}}{{ "\t" }}{{.Usage}}
   {{end}}{{end}}
`

	cli.CommandHelpTemplate = `USAGE:
    command {{.FullName}}{{if .Flags}} [command options]{{end}} [arguments...]{{if .Description}}
DESCRIPTION:
    {{.Description}}{{end}}{{if .Flags}}
OPTIONS:
    {{range .Flags}}{{.}}
    {{end}}{{end}}
`

	cli.SubcommandHelpTemplate = `USAGE:
   {{.Name}} command{{if .Flags}} [command options]{{end}} [arguments...]
COMMANDS:
   {{range .Commands}}{{join .Names ", "}}{{ "\t" }}{{.Usage}}
   {{end}}{{if .Flags}}
OPTIONS:
   {{range .Flags}}{{.}}
   {{end}}{{end}}
`
}
