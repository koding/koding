package main

import (
	"flag"
	"fmt"
	"log"
	"net/url"
	"os"

	"github.com/koding/kite"
	"github.com/koding/kite-lxc"
	"github.com/koding/kite/config"
	"github.com/koding/kite/protocol"
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

	k.HandleFunc("lxc.create", lxc.Create)
	k.HandleFunc("lxc.start", lxc.Start)
	k.HandleFunc("lxc.stop", lxc.Stop)
	k.HandleFunc("lxc.destroy", lxc.Destroy)
	k.HandleFunc("lxc.info", lxc.Info)
	k.HandleFunc("lxc.ls", lxc.Ls)

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
		proxyQuery := &protocol.KontrolQuery{
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
