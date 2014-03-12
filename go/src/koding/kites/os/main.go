// +build linux

package main

import (
	"flag"
	"fmt"
	"koding/oskite"
	"koding/tools/config"
	"koding/tools/logger"
	"log"
	"os"
	"time"
)

var (
	flagProfile      = flag.String("c", "", "Configuration profile from file")
	flagRegion       = flag.String("r", "", "Configuration region from file")
	flagDebug        = flag.Bool("d", false, "Debug mode")
	flagTemplates    = flag.String("t", "", "Change template directory")
	flagTimeout      = flag.Duration("s", time.Minute*50, "Shutdown timeout for a single VM")
	flagDisableGuest = flag.Bool("noguest", false, "Disable Guest VM creation")
	flagLimit        = flag.Int("limit", 100, "Limit total running VM on a single Container")
	flagVersion      = flag.Bool("version", false, "Show version and exit")
)

func main() {
	flag.Parse()
	if *flagProfile == "" || *flagRegion == "" {
		log.Fatal("Please specify profile via -c and region via -r. Aborting.")
	}

	var logLevel logger.Level
	if *flagDebug {
		logLevel = logger.DEBUG
	} else {
		logLevel = logger.GetLoggingLevelFromConfig("oskite", *flagProfile)
	}

	if *flagVersion {
		fmt.Println(oskite.OSKITE_VERSION)
		os.Exit(0)
	}

	os := oskite.New(config.MustConfig(*flagProfile))
	os.VmTimeout = *flagTimeout
	os.PrepareQueueLimit = 8 + 1
	os.TemplateDir = *flagTemplates
	os.LogLevel = logLevel
	os.Region = *flagRegion
	os.ActiveVMsLimit = *flagLimit
	os.DisableGuest = *flagDisableGuest

	// go go!
	os.Run()
}
