package main

import (
	"flag"
	"koding/fusetest"
	"log"
)

// Flags available on the fusetest binary
var (
	// reconnectDepth will run various suites of reconnect testing. See the
	// fusetest.ReconnectDepths map for details about the covered depths.
	reconnectDepth uint

	// mountSettingTests runs a suite of tests pertaining to mounts and mount settings.
	mountSettingTests bool

	// TODO: Implement klient tests
	// klientTests tests test general klient actions, outside of mounts.
	//klientTests bool
)

func main() {
	flag.UintVar(
		&reconnectDepth, "reconnect-depth", 0,
		"The depth at which to run reconnect tests. Higher equals longer tests. Accepted values [0-2]",
	)
	flag.BoolVar(
		&mountSettingTests, "mount-setting-tests", false,
		"Unmount and Mount the given mount with varying mount settings.",
	)
	flag.Parse()

	mountName := flag.Arg(0)
	if mountName == "" {
		log.Fatal("Pass machine name as arguments to run tests.")
	}

	opts := fusetest.FusetestOpts{
		ReconnectDepth: reconnectDepth,
		MountTests:     mountSettingTests,
	}

	f, err := fusetest.NewFusetest(mountName, opts)
	if err != nil {
		log.Fatal(err)
	}

	if err := f.RunTests(); err != nil {
		log.Fatal(err)
	}
}
