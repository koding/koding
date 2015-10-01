package main

import "github.com/codegangsta/cli"

func init() {
	cli.CommandHelpTemplate = `USAGE:
	   command {{.FullName}}{{if .Flags}} [command options]{{end}} [arguments...]{{if .Description}}
	DESCRIPTION:
	   {{.Description}}{{end}}{{if .Flags}}
	OPTIONS:
	   {{range .Flags}}{{.}}
	   {{end}}{{ end }}
`
}
