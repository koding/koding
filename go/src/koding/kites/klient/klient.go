package main

import (
	"errors"
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
	"sync"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	kiteprotocol "github.com/koding/kite/protocol"
)

var (
	flagIP          = flag.String("ip", "", "Change public ip")
	flagPort        = flag.Int("port", 56789, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagProxy       = flag.Bool("proxy", false, "Start klient behind a proxy")
	flagEnvironment = flag.String("env", protocol.Environment, "Change environment")
	flagRegion      = flag.String("region", protocol.Region, "Change region")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")

	// update paramters
	flagUpdateInterval = flag.Duration("update-interval", time.Minute*5,
		"Change interval for checking for new updates")
	flagUpdateURL = flag.String("update-url",
		"https://s3.amazonaws.com/koding-klient/"+protocol.Environment+"/latest-version.txt",
		"Change update endpoint for latest version")

	VERSION = protocol.Version
	NAME    = protocol.Name

	// this is our main reference to count and measure metrics for the klient
	usg  = usage.NewUsage()
	klog kite.Logger

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

	k := kite.New(NAME, VERSION)
	conf := config.MustGet()
	k.Config = conf
	k.Config.Port = *flagPort
	k.Config.Environment = *flagEnvironment
	k.Config.Region = *flagRegion

	klog = k.Log

	if *flagUpdateInterval < time.Minute {
		klog.Warning("Update interval can't be less than one minute. Setting to one minute.")
		*flagUpdateInterval = time.Minute
	}

	updater := &Updater{
		Endpoint: *flagUpdateURL,
		Interval: *flagUpdateInterval,
	}

	go updater.Run()

	// always boot up with the same id in the kite.key
	k.Id = conf.Id

	userIn := func(user string, users ...string) bool {
		for _, u := range users {
			if u == user {
				return true
			}
		}
		return false
	}

	// don't pass any request if the caller is outside of our scope.
	// don't allow anyone to call a method if we are during an update.
	k.PreHandleFunc(func(r *kite.Request) (interface{}, error) {
		// only authenticated methods have correct username. For example
		// kite.ping has authentication disabled so username can be empty.
		if r.Auth != nil {
			k.Log.Info("Kite '%s/%s/%s' called method: '%s'",
				r.Username, r.Client.Environment, r.Client.Name, r.Method)

			allowedUsers := []string{k.Config.Username, "koding"}
			if !userIn(r.Username, allowedUsers...) {
				return nil, fmt.Errorf("User '%s' is not allowed to make a call to us.", r.Username)
			}
		}

		updatingMu.Lock()
		defer updatingMu.Unlock()

		if updating {
			return nil, errors.New("Updating klient. Can't accept any method.")
		}

		return true, nil
	})

	// count only those methods, please add/remove methods here that will reset
	// the timer of a klient.
	usg.CountedMethods = map[string]bool{
		"fs.readDirectory":    true,
		"fs.glob":             true,
		"fs.readFile":         true,
		"fs.writeFile":        true,
		"fs.uniquePath":       true,
		"fs.getInfo":          true,
		"fs.setPermissions":   true,
		"fs.remove":           true,
		"fs.rename":           true,
		"fs.createDirectory":  true,
		"fs.move":             true,
		"fs.copy":             true,
		"webterm.getSessions": true,
		"webterm.connect":     true,
		"webterm.killSession": true,
		"exec":                true,
	}

	// we measure every incoming request
	k.PreHandleFunc(usg.Counter)

	// this provides us to get the current usage whenever we want
	k.HandleFunc("klient.usage", usg.Current)

	// also invoke updating
	k.Handle("klient.update", updater)

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

	terminal.ResetFunc = usg.Reset

	k.HandleFunc("webterm.getSessions", terminal.GetSessions)
	k.HandleFunc("webterm.connect", terminal.Connect)

	k.HandleFunc("webterm.killSession", terminal.KillSession)
	k.HandleFunc("exec", command.Exec)

	registerURL, err := getRegisterURL(k)
	if err != nil {
		log.Panic("could not get public ip" + err.Error())
	}

	if *flagRegisterURL != "" {
		u, err := url.Parse(*flagRegisterURL)
		if err != nil {
			k.Log.Fatal("Couldn't parse register url: %s", err)
		}

		registerURL = u
	}

	if registerURL == nil {
		log.Panic("register url is nil")
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
			log.Panic(err)
		}
	}

	k.Log.Info("Running as version %s", VERSION)

	k.Run()
}
