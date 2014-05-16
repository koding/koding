package main

import (
	"flag"
	"fmt"
	"koding/kodingkite"
	"koding/tools/config"
	"log"
	"os"
)

const (
	VERSION = "0.0.1"
	NAME    = "kloud"
)

var (
	flagIP      = flag.String("ip", "", "Change public ip")
	flagPort    = flag.Int("port", 3000, "Change running port")
	flagVersion = flag.Bool("version", false, "Show version and exit")
	flagRegion  = flag.String("r", "", "Change region")
	flagProfile = flag.String("c", "", "Configuration profile from file")
)

func main() {
	flag.Parse()
	if *flagProfile == "" || *flagRegion == "" {
		log.Fatal("Please specify profile via -c and region via -r. Aborting.")
	}

	if *flagVersion {
		fmt.Println(VERSION)
		os.Exit(0)
	}

	k, err := kodingkite.New(config.MustConfig(*flagProfile), NAME, VERSION)
	if err != nil {
		log.Fatalln(err)
	}

	k.Config.Region = *flagRegion
	k.Config.Port = *flagPort

	k.HandleFunc("build", build)
	k.HandleFunc("start", start)
	k.HandleFunc("stop", nil)
	k.HandleFunc("destroy", nil)
	k.HandleFunc("info", nil)

	k.Run()
}
