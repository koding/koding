// +build !urfavecli

package main

import (
	"io"
	"io/ioutil"
	"os"
	"os/signal"

	"koding/klientctl/commands"
	"koding/klientctl/commands/cli"
	"koding/klientctl/ctlcli"
	"koding/klientctl/endpoint/kloud"
	"koding/klientctl/endpoint/machine"
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

	// Initialize default client with CLI's stream. This is required until
	// machine I/O logic is moved to CLI.
	machine.DefaultClient.Stream = c

	kloud.DefaultLog = c.Log()

	if err := commands.NewKdCommand(c).Execute(); err != nil {
		c.Close()
		os.Exit(cli.ExitCodeFromError(err))
	}

	c.Close()
}

var signals = []os.Signal{
	os.Interrupt,
	os.Kill,
}

// handleSignals is used to gracefully close all resources registered to ctlcli.
func handleSignals(c *cli.CLI) {
	sigC := make(chan os.Signal, 1)
	signal.Notify(sigC, signals...)

	sig := <-sigC
	c.Log().Info("Closing after %v signal", sig)

	ctlcli.Close()
	c.Close()
	os.Exit(1)
}
