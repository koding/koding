package main

import (
	"koding/klientctl/daemon"

	"github.com/codegangsta/cli"
	"github.com/koding/logging"
)

// DaemonInstall provides a cli wrapper from daemon.Install function.
func DaemonInstall(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	opts := &daemon.Opts{
		Force:   c.Bool("force"),
		Prefix:  c.String("prefix"),
		Baseurl: c.String("baseurl"),
		Skip:    c.StringSlice("skip"),
	}

	if err := daemon.Install(opts); err != nil {
		return 1, err
	}

	return 0, nil
}

// DaemonInstall provides a cli wrapper from daemon.Install function.
func DaemonUninstall(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	opts := &daemon.Opts{
		Force: c.Bool("force"),
	}

	if err := daemon.Uninstall(opts); err != nil {
		return 1, err
	}

	return 0, nil
}

// DaemonInstall provides a cli wrapper from daemon.Install function.
func DaemonStart(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	if err := daemon.Start(); err != nil {
		return 1, err
	}

	return 0, nil
}

// DaemonInstall provides a cli wrapper from daemon.Install function.
func DaemonRestart(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	if err := daemon.Restart(); err != nil {
		return 1, err
	}

	return 0, nil
}

// DaemonInstall provides a cli wrapper from daemon.Install function.
func DaemonStop(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	if err := daemon.Stop(); err != nil {
		return 1, err
	}

	return 0, nil
}

// DaemonUpdate provides a cli wrapper for daemon.Update function.
func DaemonUpdate(c *cli.Context, _ logging.Logger, _ string) (int, error) {
	opts := &daemon.Opts{
		Force: c.Bool("force"),
	}

	if err := daemon.Update(opts); err != nil {
		return 1, err
	}

	return 0, nil
}
