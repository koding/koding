package main

import (
	"flag"
	"fmt"
	"koding/kite-handler/command"
	"koding/kite-handler/fs"
	"koding/kite-handler/terminal"
	"koding/kites/klient/protocol"
	"koding/kites/klient/usage"
	"log"
	"net/url"
	"os"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	kiteprotocol "github.com/koding/kite/protocol"
)

var (
	flagIP          = flag.String("ip", "", "Change public ip")
	flagPort        = flag.Int("port", 3000, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagLocal       = flag.Bool("local", false, "Start klient in local environment.")
	flagProxy       = flag.Bool("proxy", false, "Start klient behind a proxy")
	flagEnvironment = flag.String("env", protocol.Environment, "Change environment")
	flagRegion      = flag.String("region", protocol.Region, "Change region")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")

	VERSION = protocol.Version
	NAME    = protocol.Name

	// this is our main reference to count and measure metrics for the klient
	usg = usage.NewUsage()
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

	// always boot up with the same id in the kite.key
	k.Id = conf.Id

	// we measure every incoming request
	k.PreHandleFunc(usg.Counter)

	// this provides us to get the current usage whenever we want
	k.HandleFunc("klient.usage", usg.Current)
	k.HandleFunc("klient.update", updater)

	k.HandleFunc("fs.readDirectory", fs.ReadDirectory)
	k.HandleFunc("fs.glob", fs.Glob)
	k.HandleFunc("fs.readFile", fs.ReadFile)
	k.HandleFunc("fs.writeFile", fs.WriteFile)
	k.HandleFunc("fs.uniquePath", fs.UniquePath)
	k.HandleFunc("fs.getInfo", fs.GetInfo)
	k.HandleFunc("fs.setPermissions", fs.SetPermissions)
	k.HandleFunc("fs.remove", fs.Remove)
	k.HandleFunc("fs.rename", fs.Rename)
	k.HandleFunc("fs.createDirectory", fs.CreateDirectory)
	k.HandleFunc("fs.move", fs.Move)
	k.HandleFunc("fs.copy", fs.Copy)

	k.HandleFunc("webterm.getSessions", terminal.GetSessions)
	k.HandleFunc("webterm.connect", terminal.Connect)
	k.HandleFunc("webterm.killSession", terminal.KillSession)

	k.HandleFunc("exec", command.Exec)

	// return current version of klient
	k.HandleFunc("version", func(r *kite.Request) (interface{}, error) { return VERSION, nil })

	registerURL := k.RegisterURL(*flagLocal)
	if *flagRegisterURL != "" {
		u, err := url.Parse(*flagRegisterURL)
		if err != nil {
			k.Log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	k.Log.Info("Going to register to kontrol with URL: %s", registerURL)
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
			log.Fatal(err)
		}
	}

	go func() {
		kloud, err := NewKloud(k)
		if err != nil {
			k.Log.Warning(err.Error())
		}

		for _ = range time.Tick(time.Second * 5) {
			err := kloud.Report()
			fmt.Printf("err %+v\n", err)
		}

	}()

	k.Run()
}
