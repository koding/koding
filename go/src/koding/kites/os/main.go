package main

import (
	"flag"
	"koding/oskite"
	"koding/tools/config"
	"koding/tools/logger"
	"log"
	"time"
)

var (
	flagProfile      = flag.String("c", "", "Configuration profile from file")
	flagRegion       = flag.String("r", "", "Configuration region from file")
	flagDebug        = flag.Bool("d", false, "Debug mode")
	flagTemplates    = flag.String("t", "", "Change template directory")
	flagTimeout      = flag.String("s", "50m", "Shut down timeout for a single VM")
	flagDisableGuest = flag.Bool("noguest", false, "Disable Guest VM creation")
	flagLimit        = flag.Int("limit", 100, "Limit total running VM on a single Container")
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

	timeout, err := time.ParseDuration(*flagTimeout)
	if err != nil {
		log.Printf("Timeout flag is wrong: %v. Using standart timeout", err.Error())
		timeout = time.Minute * 50
	} else {
		// use our new timeout
		log.Println("Using default VM timeout: %s", timeout)
	}

	os := oskite.New(config.MustConfig(*flagProfile))
	os.VmTimeout = timeout
	os.PrepareQueueLimit = 8 + 1
	os.TemplateDir = *flagTemplates
	os.LogLevel = logLevel
	os.Region = *flagRegion
	os.ActiveVMsLimit = *flagLimit
	os.DisableGuest = *flagDisableGuest

	// go go!
	os.Run()
}
