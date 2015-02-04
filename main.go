package main

import (
	"flag"
	"fmt"
	"os"
	"sync"
	"time"

	"github.com/koding/klient/protocol"
)

var (
	flagIP          = flag.String("ip", "", "Change public ip")
	flagPort        = flag.Int("port", 56789, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagEnvironment = flag.String("env", protocol.Environment, "Change environment")
	flagRegion      = flag.String("region", protocol.Region, "Change region")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
	flagDebug       = flag.Bool("debug", false, "Debug mode")

	// update parameters
	flagUpdateInterval = flag.Duration("update-interval", time.Minute*5,
		"Change interval for checking for new updates")
	flagUpdateURL = flag.String("update-url",
		"https://s3.amazonaws.com/koding-klient/"+protocol.Environment+"/latest-version.txt",
		"Change update endpoint for latest version")

	// These are assigned during the go build process via ldflags
	VERSION = protocol.Version
	NAME    = protocol.Name

	// we also could use an atomic boolean this is simple for now.
	updating   = false
	updatingMu sync.Mutex // protects updating
)

func main() {
	flag.Parse()
	if *flagVersion {
		fmt.Println(VERSION)
		os.Exit(0)
	}

	k := NewKlient()
	defer k.Close()

	k.log.Info("Running as version %s", VERSION)
	k.Run()
}
