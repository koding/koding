// +build linux

package main

import (
	"flag"
	"fmt"
	"koding/terminal"
	"koding/tools/config"
	"koding/tools/logger"
	"log"
	"os"
)

var (
	flagProfile = flag.String("c", "", "Configuration profile from file")
	flagRegion  = flag.String("r", "", "Configuration region from file")
	flagDebug   = flag.Bool("d", false, "Debug mode")
	flagVersion = flag.Bool("version", false, "Show version and exit")
	flagPort    = flag.Int("p", 0, "Kite port")
)

func main() {
	if *flagVersion {
		fmt.Println(terminal.TERMINAL_VERSION)
		os.Exit(0)
	}

	flag.Parse()
	if *flagProfile == "" || *flagRegion == "" {
		log.Fatalf("Please specify profile via -c and region via -r. Aborting.")
	}

	var logLevel logger.Level
	if *flagDebug {
		logLevel = logger.DEBUG
	} else {
		logLevel = logger.GetLoggingLevelFromConfig("terminal", *flagProfile)
	}

	term := terminal.New(config.MustConfig(*flagProfile))
	term.LogLevel = logLevel
	term.Region = *flagRegion
	term.Port = *flagPort

	// go go!
	term.Run()
}
