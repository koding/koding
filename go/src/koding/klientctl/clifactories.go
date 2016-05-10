// ctifactories implements abstractions ontop of the CLI commands, interfacting the
// CLI library of choice with the klientctl Commands created.
//
// TODO: Move this to it's own package, once the rest of the klientctl lib is
// package-able.
package main

import (
	"fmt"
	"koding/klientctl/autocomplete"
	"koding/klientctl/config"
	"koding/klientctl/ctlcli"
	"koding/klientctl/klient"
	"koding/klientctl/metrics"
	"koding/klientctl/remount"
	"koding/klientctl/repair"
	"koding/mountcli"
	"os"
	"strings"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
	"github.com/koding/service"
)

// MountCommandFactory creates a mount.Command instance and runs it with
// Stdin and Out.
func MountCommandFactory(c *cli.Context, log logging.Logger, cmdName string) ctlcli.Command {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	opts := MountOptions{
		Name:             c.Args().Get(0),
		LocalPath:        c.Args().Get(1),
		RemotePath:       c.String("remotepath"), // note the lowercase of all chars
		NoIgnore:         c.Bool("noignore"),
		NoPrefetchMeta:   c.Bool("noprefetch-meta"),
		NoWatch:          c.Bool("nowatch"),
		PrefetchAll:      c.Bool("prefetch-all"),
		PrefetchInterval: c.Int("prefetch-interval"),
		Trace:            c.Bool("trace"),
		OneWaySync:       c.Bool("oneway-sync"),
		OneWayInterval:   c.Int("oneway-interval"),
		Debug:            c.Bool("debug"),

		// Used for prefetch
		SSHDefaultKeyDir:  config.SSHDefaultKeyDir,
		SSHDefaultKeyName: config.SSHDefaultKeyName,
	}

	return &MountCommand{
		Options:       opts,
		Stdout:        os.Stdout,
		Stdin:         os.Stdin,
		Log:           log,
		KlientOptions: klient.NewKlientOptions(),
		helper:        ctlcli.CommandHelper(c, "mount"),
		homeDirGetter: homeDirGetter,
	}
}

// UnmountCommandFactory creates a UnmountCommand instance and runs it with
// Stdin and Out.
func UnmountCommandFactory(c *cli.Context, log logging.Logger, cmdName string) ctlcli.Command {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	// Full our unmount options from the CLI. Any empty options are okay, as
	// the command struct is responsible for verifying valid opts.
	opts := UnmountOptions{
		MountName: c.Args().First(),
	}

	return &UnmountCommand{
		Options:       opts,
		Stdout:        os.Stdout,
		Stdin:         os.Stdin,
		Log:           log,
		KlientOptions: klient.NewKlientOptions(),
		helper:        ctlcli.CommandHelper(c, cmdName),
		healthChecker: defaultHealthChecker,
		fileRemover:   os.Remove,
		mountFinder:   mountcli.NewMountcli(),
	}
}

// RepairCommandFactory creates a repair.Command instance and runs it with
// Stdin and Out.
func RepairCommandFactory(c *cli.Context, log logging.Logger, cmdName string) ctlcli.Command {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	// Fill our repair options from the CLI. Any empty options are okay, as
	// the command struct is responsible for verifying valid opts.
	opts := repair.Options{
		MountName: c.Args().First(),
		Version:   config.VersionNum(),
	}

	return &repair.Command{
		Options:       opts,
		Stdout:        os.Stdout,
		Stdin:         os.Stdin,
		Log:           log,
		KlientOptions: klient.NewKlientOptions(),
		Helper:        ctlcli.CommandHelper(c, cmdName),
		// Used to create our KlientService instance. Really needs to be improved in
		// the future, once it has proper access to a config package
		ServiceConstructor: func() (service.Service, error) { return newService(nil) },
	}
}

func MetricsCommandFactory(c *cli.Context, log logging.Logger, cmdName string) int {
	return metrics.MetricsCommand(c, log, ConfigFolder)
}

func RemountCommandFactory(c *cli.Context, _ logging.Logger, _ string) int {
	if len(c.Args()) != 1 {
		cli.ShowCommandHelp(c, "remount")
		return 1
	}

	cmd := remount.RemountCommand{
		MountName:     c.Args()[0],
		KlientOptions: klient.NewKlientOptions(),
	}

	if err := cmd.Run(); err != nil {
		fmt.Printf("Error: %s", err)
		return 1
	}

	return 0
}

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
