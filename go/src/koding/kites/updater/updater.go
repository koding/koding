package main

import (
	"flag"
	"fmt"
	"koding/kites/klient/protocol"
	"log"
	"net/url"
	"os"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
)

var (
	flagIP          = flag.String("ip", "", "Change public ip")
	flagPort        = flag.Int("port", 3333, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagEnvironment = flag.String("env", protocol.Environment, "Change environment")
	flagRegion      = flag.String("region", protocol.Region, "Change region")
	flagLocal       = flag.Bool("local", false, "Start klient in local environment.")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
)

const (
	VERSION = "0.0.1"
	NAME    = "updater"
)

func main() {
	flag.Parse()
	if *flagVersion {
		fmt.Println(VERSION)
		os.Exit(0)
	}

	k := kite.New(NAME, VERSION)
	conf := config.MustGet()
	k.Config = conf
	k.Config.Port = *flagPort
	k.Config.Environment = *flagEnvironment
	k.Config.Region = *flagRegion

	registerURL := k.RegisterURL(*flagLocal)
	if *flagRegisterURL != "" {
		u, err := url.Parse(*flagRegisterURL)
		if err != nil {
			k.Log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	if err := k.RegisterForever(registerURL); err != nil {
		log.Fatal(err)
	}

	k.Run()
}
