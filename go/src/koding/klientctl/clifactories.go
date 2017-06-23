package main

// ctifactories implements abstractions ontop of the CLI commands, interfacting the
// CLI library of choice with the klientctl Commands created.
//
// TODO: Move this to it's own package, once the rest of the klientctl lib is
// package-able.

import (
	"fmt"
	"os"
	"strings"

	"koding/klientctl/autocomplete"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/klient"
	"koding/klientctl/logcmd"
	"koding/klientctl/open"
	"koding/klientctl/status"

	"github.com/koding/logging"
	cli "gopkg.in/urfave/cli.v1"
)

// TODO(leeola): deprecate this default, instead passing it as a dependency
// to the users of it.
var defaultHealthChecker *status.HealthChecker

// AutocompleteCommandFactory creates a autocomplete.Command instance and runs it with
// Stdin and Out.
func AutocompleteCommandFactory(c *cli.Context, log logging.Logger, cmdName string) ctlcli.Command {
	opts := autocomplete.Options{
		Shell:   strings.ToLower(c.Args().First()),
		FishDir: c.String("fish-dir"),
		Bashrc:  !c.Bool("no-bash-source"),
		BashDir: c.String("bash-dir"),
	}

	init := autocomplete.Init{
		Stdout: os.Stdout,
		Log:    log,
		Helper: ctlcli.CommandHelper(c, cmdName),
	}

	cmd, err := autocomplete.NewCommand(init, opts)
	if err != nil {
		return ctlcli.NewErrorCommand(
			os.Stdout, log, err,
			"Unable to create autocomplete command",
		)
	}

	return cmd
}

func LogCommandFactory(c *cli.Context, log logging.Logger, cmdName string) ctlcli.Command {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	// Fill our repair options from the CLI. Any empty options are okay, as
	// the command struct is responsible for verifying valid opts.
	opts := logcmd.Options{
		Debug:             c.Bool("debug") || config.Konfig.Debug,
		KdLog:             !c.Bool("no-kd-log"),
		KlientLog:         !c.Bool("no-klient-log"),
		KdLogLocation:     c.String("kd-log-file"),
		KlientLogLocation: c.String("klient-log-file"),
		Lines:             c.Int("lines"),
	}

	init := logcmd.Init{
		Stdout: os.Stdout,
		Log:    log,
		Helper: ctlcli.CommandHelper(c, cmdName),
	}

	cmd, err := logcmd.NewCommand(init, opts)
	if err != nil {
		return ctlcli.NewErrorCommand(
			os.Stdout, log, err,
			"Unable to create log command",
		)
	}

	return cmd
}

func OpenCommandFactory(c *cli.Context, log logging.Logger, cmdName string) ctlcli.Command {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	// Fill our options from the CLI. Any empty options are okay, as
	// the command struct is responsible for verifying valid opts.
	opts := open.Options{
		Filepaths: c.Args(),
		Debug:     c.Bool("debug") || config.Konfig.Debug,
	}

	init := open.Init{
		Stdout:        os.Stdout,
		KlientOptions: klient.NewKlientOptions(),
		Log:           log,
		Helper:        ctlcli.CommandHelper(c, cmdName),
	}

	cmd, err := open.NewCommand(init, opts)
	if err != nil {
		return ctlcli.NewErrorCommand(
			os.Stdout, log, err,
			"Unable to create open command",
		)
	}

	return cmd
}
