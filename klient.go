package main

import (
	"errors"
	"flag"
	"fmt"
	"net"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"koding/kite-handler/command"
	"koding/kite-handler/docker"
	"koding/kite-handler/fs"
	"koding/kite-handler/terminal"
	"koding/kites/klient/collaboration"
	"koding/kites/klient/protocol"
	"koding/kites/klient/usage"

	"github.com/koding/kite"
	"github.com/koding/kite/config"
)

var (
	flagIP          = flag.String("ip", "", "Change public ip")
	flagPort        = flag.Int("port", 56789, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagEnvironment = flag.String("env", protocol.Environment, "Change environment")
	flagRegion      = flag.String("region", protocol.Region, "Change region")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
	flagDebug       = flag.Bool("debug", false, "Debug mode")

	// update paramters
	flagUpdateInterval = flag.Duration("update-interval", time.Minute*5,
		"Change interval for checking for new updates")
	flagUpdateURL = flag.String("update-url",
		"https://s3.amazonaws.com/koding-klient/"+protocol.Environment+"/latest-version.txt",
		"Change update endpoint for latest version")

	VERSION = protocol.Version
	NAME    = protocol.Name

	// this is our main reference to count and measure metrics for the klient
	// we count only those methods, please add/remove methods here that will
	// reset the timer of a klient.
	usg = usage.NewUsage(map[string]bool{
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
		"klient.share":        true,
		"klient.unshare":      true,
		"klient.shared":       true,
	})

	// this is used to allow other users to call any klient method.
	collab = collaboration.New()

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

	k := newKite()

	// Close the klient.db in any case. Corrupt db would be catastrophic
	defer collab.Close()

	k.Log.Info("Running as version %s", VERSION)
	k.Run()
}

func newKite() *kite.Kite {
	k := kite.New(NAME, VERSION)

	if *flagDebug {
		k.SetLogLevel(kite.DEBUG)
	}

	conf := config.MustGet()
	k.Config = conf
	k.Config.Port = *flagPort
	k.Config.Environment = *flagEnvironment
	k.Config.Region = *flagRegion
	k.Id = conf.Id // always boot up with the same id in the kite.key

	// FIXME: It's ugly I know. It's a fix for Koding local development and is
	// needed
	if !strings.Contains(k.Config.KontrolURL, "ngrok") {
		// override current kontrolURL so it talks to port 3000, this is needed
		// because ELB can forward requests based on ports. The port 80 and 443 are
		// HTTP/HTTPS only so our kite can't connect it (we use websocket). However
		// We have a TCP proxy at 3000 which allows us to connect via WebSocket.
		u, _ := url.Parse(k.Config.KontrolURL)

		host := u.Host
		if HasPort(u.Host) {
			host, _, _ = net.SplitHostPort(u.Host)
		}

		u.Host = AddPort(host, "3000")
		u.Scheme = "http"
		k.Config.KontrolURL = u.String()
	}

	if *flagUpdateInterval < time.Minute {
		k.Log.Warning("Update interval can't be less than one minute. Setting to one minute.")
		*flagUpdateInterval = time.Minute
	}

	updater := &Updater{
		Endpoint: *flagUpdateURL,
		Interval: *flagUpdateInterval,
		Log:      k.Log,
	}

	// before we register check for latest update and re-update itself before
	// we continue
	k.Log.Info("Checking for new updates")
	if err := updater.checkAndUpdate(); err != nil {
		k.Log.Warning("Self-update: %s", err)
	}

	go updater.Run()

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

			// Allow these users by default
			allowedUsers := []string{k.Config.Username, "koding"}

			// Allow collaboration users as well
			sharedUsers, err := collab.GetAll()
			if err != nil {
				return nil, fmt.Errorf("Can't read shared users from the storage. Err: %v", err)
			}
			allowedUsers = append(allowedUsers, sharedUsers...)

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

	// Metrics, is used by Kloud to get usage so Kloud can stop free VMs
	k.PreHandleFunc(usg.Counter) // we measure every incoming request
	k.HandleFunc("klient.usage", usg.Current)

	// Collaboration, is used by our Koding.com browser client
	k.HandleFunc("klient.share", collab.Share)
	k.HandleFunc("klient.unshare", collab.Unshare)
	k.HandleFunc("klient.shared", collab.Shared)

	// Filesystem
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

	// Docker
	dock := docker.New("tcp")
	k.HandleFunc("docker.build", dock.Build)
	k.HandleFunc("docker.create", dock.Create)
	k.HandleFunc("docker.connect", dock.Connect)
	k.HandleFunc("docker.stop", dock.Stop)
	k.HandleFunc("docker.start", dock.Start)
	k.HandleFunc("docker.kill", dock.Kill)
	k.HandleFunc("docker.destroy", dock.Destroy)
	k.HandleFunc("docker.list", dock.List)

	// Execution
	k.HandleFunc("exec", command.Exec)

	// Terminal
	term := terminal.New(k.Log)
	term.InputHook = usg.Reset
	k.HandleFunc("webterm.getSessions", term.GetSessions)
	k.HandleFunc("webterm.connect", term.Connect)
	k.HandleFunc("webterm.killSession", term.KillSession)
	k.HandleFunc("webterm.killSessions", term.KillSessions)

	// Unshare collab users if the klient owner disconnects
	k.OnDisconnect(func(c *kite.Client) {
		k.Log.Info("Kite '%s/%s/%s' is disconnected", c.Username, c.Environment, c.Name)
		if c.Username != k.Config.Username {
			return // we don't care for others
		}

		sharedUsers, err := collab.GetAll()
		if err != nil {
			k.Log.Warning("Couldn't unshare users: '%s'", err)
			return
		}

		if len(sharedUsers) == 0 {
			return // nothing to do ...
		}

		k.Log.Info("Unsharing users '%s'", sharedUsers)
		for _, user := range sharedUsers {
			if err := collab.Delete(user); err != nil {
				k.Log.Warning("Couldn't delete user from storage: '%s'", err)
			}

			// close all active sessions of the current
			term.CloseSessions(user)
		}
	})

	if err := register(k); err != nil {
		panic(err)
	}

	return k
}

// Given a string of the form "host", "host:port", or "[ipv6::address]:port",
// return true if the string includes a port.
func HasPort(s string) bool { return strings.LastIndex(s, ":") > strings.LastIndex(s, "]") }

// Given a string of the form "host", "port", returns "host:port"
func AddPort(host, port string) string {
	if ok := HasPort(host); ok {
		return host
	}

	return host + ":" + port
}
