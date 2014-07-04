package main

import (
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	kiteprotocol "github.com/koding/kite/protocol"
)

const (
	Name    = "hypervisor"
	Version = "0.0.1"
)

var (
	flagPort        = flag.Int("port", 9999, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagLocal       = flag.Bool("local", false, "Start klient in local environment.")
	flagProxy       = flag.Bool("proxy", false, "Start klient behind a proxy")
	flagEnvironment = flag.String("env", "", "Change environment")
	flagRegion      = flag.String("region", "", "Change region")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
)

func main() {
	flag.Parse()
	if *flagVersion {
		fmt.Println(Version)
		os.Exit(0)
	}

	err := runMain()
	if err != nil {
		log.Printf("%s: %s\n", Name, err)
	}
}

func runMain() error {
	k := kite.New(Name, Version)
	conf := config.MustGet()
	k.Config = conf
	k.Config.Port = *flagPort

	if *flagRegion != "" {
		k.Config.Region = *flagRegion
	}

	if *flagEnvironment != "" {
		k.Config.Environment = *flagEnvironment
	}

	k.HandleFunc("create", nil)
	k.HandleFunc("start", nil)
	k.HandleFunc("stop", nil)
	k.HandleFunc("destroy", nil)
	k.HandleFunc("info", nil)
	k.HandleFunc("ls", nil)

	registerURL := k.RegisterURL(*flagLocal)
	if *flagRegisterURL != "" {
		u, err := url.Parse(*flagRegisterURL)
		if err != nil {
			return fmt.Errorf("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	if *flagProxy {
		// Koding proxies in production only
		proxyQuery := &kiteprotocol.KontrolQuery{
			Username:    "koding",
			Environment: "production",
			Name:        "proxy",
		}

		k.Log.Info("Seaching proxy: %#v", proxyQuery)
		go k.RegisterToProxy(registerURL, proxyQuery)
	} else {
		if err := k.RegisterForever(registerURL); err != nil {
			return err
		}
	}

	k.Run()
	return nil
}
