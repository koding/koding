package main

import (
	"flag"
	"koding/fusetest"
	"log"
)

// Flags available on the fusetest binary
var (
	// Run all the tests, at the maximum depth.
	all bool

	// Run all the tests except especially slow tests, like reconnect.
	almostAll bool

	// The fuseOpTests, to be run on the existing mount, mount-settings mounts, and
	// anytime the fs needs to be confirmed in working order (reconnect, etc).
	disableFuseOpsTests bool

	// reconnectDepth will run various suites of reconnect testing. See the
	// fusetest.ReconnectDepths map for details about the covered depths.
	reconnectDepth uint

	// mountSettingTests runs a suite of tests pertaining to mounts and mount settings.
	mountSettingTests bool

	// Run general kd tests, not including mount setting tests.
	miscTests bool

	// Run misc tests that require sudo. These are randomly assorted, because of the
	// use of sudo.
	miscSudoTests bool
)

func main() {
	flag.BoolVar(
		&all, "all", false,
		"Run *all* tests. Warning: This is will take upwards of 10-20m.",
	)
	flag.BoolVar(
		&almostAll, "almost-all", false,
		"Run all tests, excluding the long running/slow tests.",
	)
	flag.BoolVar(
		&disableFuseOpsTests, "disable-fuse-ops", false,
		"The fuseop tests, confirming the fuse fs is in working condition.",
	)
	flag.UintVar(
		&reconnectDepth, "reconnect-depth", 0,
		"The depth at which to run reconnect tests. Higher equals longer tests. Accepted values [0-2]",
	)
	flag.BoolVar(
		&mountSettingTests, "mount-settings", false,
		"Unmount and Mount the given mount with varying mount settings.",
	)
	flag.BoolVar(
		&miscTests, "misc", false,
		"General kd tests, not including Mount/Unmount tests.",
	)
	flag.BoolVar(
		&miscSudoTests, "misc-sudo", false,
		"General kd tests that require sudo. This flag must be explicitly included. -all does not include this flag.",
	)
	flag.Parse()

	// If all flag was given, set the reconnect depth to max. We'll set the rest of the
	// settings below, with the all||almostAll if check.
	if all {
		reconnectDepth = 2
	}

	// If the flag all or almostAll was used, set the rest of the flags as needed.
	if all || almostAll {
		miscTests = true
		mountSettingTests = true
	}

	mountName := flag.Arg(0)
	if mountName == "" {
		log.Fatalf("Pass machine name as arguments to run tests.")
	}

	opts := fusetest.FusetestOpts{
		FuseOpsTests:      !disableFuseOpsTests,
		ReconnectDepth:    reconnectDepth,
		MountSettingTests: mountSettingTests,
		MiscTests:         miscTests,
		MiscSudoTests:     miscSudoTests,
	}

	f, err := fusetest.NewFusetest(mountName, opts)
	if err != nil {
		log.Fatal(err)
	}

	if err := f.RunTests(); err != nil {
		log.Fatal(err)
	}
}
