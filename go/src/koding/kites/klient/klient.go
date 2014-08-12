package main

import (
	"flag"
	"fmt"
	"koding/kite-handler/command"
	"koding/kite-handler/fs"
	"koding/kite-handler/terminal"
	"koding/kites/klient/protocol"
	"koding/kites/klient/usage"
	"koding/tools/etcd"
	"log"
	"math/rand"
	"net/url"
	"os"
	"time"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
	"github.com/koding/kite/kitekey"
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
	flagKontrolURL  = flag.String("kontrol-url", "", "Kontrol URL to be connected")

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

// kontrolURL returns a kontrol URL that kloud is going to connect. First it
// tries to read from kite.key. If -discovery flag is enabled it search it from
// the discovery endpoint. If -kontrol-url is given explicitly it's going to
// use that.
// TODO: duplicate code in kloud and klient
func kontrolURL(k *kite.Kite) string {
	kontrolURL := config.MustGet().KontrolURL
	k.Log.Info("Reading kontrol URL from kite.key as: %s", kontrolURL)

	// no need to check for err, because config.MustGet() already panic for parsing
	key, _ := kitekey.Parse()

	if discoveryURL, ok := key.Claims["discoveryURL"].(string); ok {
		k.Log.Info("Discovery enabled. Searching for a production kontrol at %s ...", discoveryURL)

		etcd.DefaultDiscoveryURL = discoveryURL

		query := &kiteprotocol.KontrolQuery{
			Username:    "koding",
			Environment: "production",
			Name:        "kontrol",
		}

		kontrols, err := etcd.Kontrols(query)
		if err != nil {
			k.Log.Warning("Discovery couldn't find any kontrol: %s. Going to use default URL", err)
		} else {
			index := rand.Intn(len(kontrols))
			kontrolURL = kontrols[index].URL // pick up a random kite
			k.Log.Info("Discovery found a production kontrol. Going to use it: %s", kontrolURL)
		}
	}

	if *flagKontrolURL != "" {
		u, err := url.Parse(*flagKontrolURL)
		if err != nil {
			log.Fatalln(err)
		}

		k.Log.Info("Kontrol URL is given explicitly. Going to use: %s", u.String())
		kontrolURL = u.String()
	}

	// we are going to use our final url for kontrol queries and registering
	k.Config.KontrolURL = kontrolURL

	return kontrolURL
}
