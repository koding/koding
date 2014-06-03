package main

import (
	"flag"
	"fmt"
	"koding/kite-handler/command"
	"koding/kite-handler/fs"
	"koding/kite-handler/terminal"
	"koding/kites/klient/protocol"
	"log"
	"net"
	"net/url"
	"os"
	"strconv"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
)

const (
	VERSION = protocol.Version
	NAME    = protocol.Name
)

var (
	flagIP      = flag.String("ip", "", "Change public ip")
	flagPort    = flag.Int("port", 3000, "Change running port")
	flagVersion = flag.Bool("version", false, "Show version and exit")
	flagLocal   = flag.Bool("local", false, "Start klient in local environment.")
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
	k.Config.Environment = protocol.Environment
	k.Config.Region = protocol.Region

	// always boot up with the same id in the kite.key
	k.Id = conf.Id

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

	if err := k.RegisterForever(registerURL()); err != nil {
		log.Fatal(err)
	}

	k.Run()
}

func registerURL() *url.URL {
	l := &localhost{}

	var ip net.IP
	var err error

	if *flagLocal {
		ip, err = l.LocalIP()
		if err != nil {
			return nil
		}
	} else {
		ip, err = l.PublicIp()
		if err != nil {
			return nil
		}
	}

	return &url.URL{
		Scheme: "ws",
		Host:   ip.String() + ":" + strconv.Itoa(*flagPort),
		Path:   "/" + NAME + "-" + VERSION,
	}
}
