package main

import (
	"flag"
	"fmt"
	"koding/kite-handler/fs"
	"koding/kite-handler/terminal"
	"log"
	"net/url"
	"os"
	"strconv"

	"github.com/koding/kite"
)

const (
	VERSION = "0.0.1"
	NAME    = "klient"
)

var (
	flagIP      = flag.String("ip", "", "Change public ip")
	flagPort    = flag.Int("port", 3000, "Change running port")
	flagVersion = flag.Bool("version", false, "Show version and exit")
)

func main() {
	flag.Parse()
	if *flagVersion {
		fmt.Println(VERSION)
		os.Exit(0)
	}

	k := kite.New(NAME, VERSION)
	k.Config.Port = *flagPort

	u, _ := url.Parse("wss://kontrol.koding.com")
	k.Config.KontrolURL = u

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

	if err := k.RegisterForever(registerURL()); err != nil {
		log.Fatal(err)
	}

	k.Run()
}

func registerURL() *url.URL {
	l := &localhost{}
	p, err := l.PublicIp()
	if err != nil {
		return nil
	}

	return &url.URL{
		Scheme: "ws",
		Host:   p.String() + ":" + strconv.Itoa(*flagPort),
		Path:   "/" + NAME + "-" + VERSION,
	}
}
