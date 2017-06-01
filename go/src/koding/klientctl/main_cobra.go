// +build cobra

package main

import (
	"io"
	"io/ioutil"
	"os"

	"fmt"
	"koding/klientctl/commands"
	"koding/klientctl/commands/cli"
	"koding/klientctl/ctlcli"
)

func main() {
	// Initialize log handler.
	var logHandler io.Writer = ioutil.Discard
	if f, err := os.OpenFile(LogFilePath, os.O_WRONLY|os.O_APPEND, 0666); err == nil {
		logHandler = f
		ctlcli.CloseOnExit(f)
	}

	c := cli.NewCLI(os.Stdin, os.Stdout, os.Stderr, logHandler)
	if err := commands.NewKdCommand(c).Execute(); err != nil {
		fmt.Fprintln(c.Err(), err)
		os.Exit(cli.ExitCodeFromError(err))
	}
}
