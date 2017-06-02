// +build cobra

package main

import (
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"os/signal"

	"koding/klientctl/commands"
	"koding/klientctl/commands/cli"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
)

func main() {
	// Initialize log handler.
	var logHandler io.Writer = ioutil.Discard
	if f, err := os.OpenFile(LogFilePath, os.O_WRONLY|os.O_APPEND, 0666); err == nil {
		logHandler = f
		ctlcli.CloseOnExit(f)
	}

	c := cli.NewCLI(os.Stdin, os.Stdout, os.Stderr, logHandler)
	go handleSignals(c) // Start signal handler.

	kloud.DefaultLog = log

	if err := commands.NewKdCommand(c).Execute(); err != nil {
		fmt.Fprintln(c.Err(), err)

		c.Close()
		os.Exit(cli.ExitCodeFromError(err))
	}

	c.Close()
}

// handleSignals is used to gracefully close all resources registered to ctlcli.
func handleSignals(c *cli.CLI) {
	sigC := make(chan os.Signal, 1)
	signal.Notify(sig, os.Interrupt, os.Kill)

	sig := <-sigC
	c.Log().Info("Closing after %v signal", sig)

	ctlcli.Close()
	c.Close()
	os.Exit(1)
}
