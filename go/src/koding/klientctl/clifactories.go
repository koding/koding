package main

// ctifactories implements abstractions ontop of the CLI commands, interfacting the
// CLI library of choice with the klientctl Commands created.
//
// TODO: Move this to it's own package, once the rest of the klientctl lib is
// package-able.

import (
	"fmt"
	"koding/klientctl/autocomplete"
	"koding/klientctl/config"
	"koding/klientctl/cp"
	"koding/klientctl/ctlcli"
	"koding/klientctl/klient"
	"koding/klientctl/logcmd"
	"koding/klientctl/metrics"
	"koding/klientctl/open"
	"koding/klientctl/remount"
	"koding/klientctl/repair"
	"koding/klientctl/sync"
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
		Debug:            c.Bool("debug") || config.Konfig.Debug,
		Fuse:             c.Bool("fuse"),

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

func SyncCommandFactory(c *cli.Context, log logging.Logger, cmdName string) ctlcli.Command {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	// Fill our repair options from the CLI. Any empty options are okay, as
	// the command struct is responsible for verifying valid opts.
	opts := sync.Options{
		Debug:         c.Bool("debug") || config.Konfig.Debug,
		MountName:     c.Args().First(),
		SyncDirection: c.Args().Get(1), // Get the 2nd arg

		// Used for prefetch
		SSHDefaultKeyDir:  config.SSHDefaultKeyDir,
		SSHDefaultKeyName: config.SSHDefaultKeyName,
	}

	init := sync.Init{
		Stdout:        os.Stdout,
		Log:           log,
		KlientOptions: klient.NewKlientOptions(),
		Helper:        ctlcli.CommandHelper(c, cmdName),
		HomeDirGetter: homeDirGetter,
		HealthChecker: defaultHealthChecker,
	}

	cmd, err := sync.NewCommand(init, opts)
	if err != nil {
		return ctlcli.NewErrorCommand(
			os.Stdout, log, err,
			"Unable to create sync command",
		)
	}

	return cmd
}

func CpCommandFactory(c *cli.Context, log logging.Logger, cmdName string) ctlcli.Command {
	log = log.New(fmt.Sprintf("command:%s", cmdName))

	// Fill our repair options from the CLI. Any empty options are okay, as
	// the command struct is responsible for verifying valid opts.
	opts := cp.Options{
		Debug:       c.Bool("debug") || config.Konfig.Debug,
		Source:      c.Args().First(),
		Destination: c.Args().Get(1), // Get the 2nd arg

		// Used for prefetch
		SSHDefaultKeyDir:  config.SSHDefaultKeyDir,
		SSHDefaultKeyName: config.SSHDefaultKeyName,
	}

	init := cp.Init{
		Stdout:        os.Stdout,
		Log:           log,
		KlientOptions: klient.NewKlientOptions(),
		Helper:        ctlcli.CommandHelper(c, cmdName),
		HomeDirGetter: homeDirGetter,
		HealthChecker: defaultHealthChecker,
	}

	cmd, err := cp.NewCommand(init, opts)
	if err != nil {
		return ctlcli.NewErrorCommand(
			os.Stdout, log, err,
			"Unable to create cp command",
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
