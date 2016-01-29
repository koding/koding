package main

import (
	"flag"
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"time"

	"github.com/koding/klient/app"
	"github.com/koding/klient/protocol"
	"github.com/koding/klient/registration"
)

var (
	flagIP          = flag.String("ip", "", "Change public ip")
	flagPort        = flag.Int("port", 56789, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
	flagDebug       = flag.Bool("debug", false, "Debug mode")
	flagScreenrc    = flag.String("screenrc", "/opt/koding/etc/screenrc", "Default screenrc path")
	flagDBPath      = flag.String("dbpath", "", "Bolt DB database path. Must be absolute)")

	// Registration flags
	flagKiteHome   = flag.String("kite-home", "~/.kite/", "Change kite home path")
	flagUsername   = flag.String("username", "", "Username to be registered to Kontrol")
	flagToken      = flag.String("token", "", "Token to be passed to Kontrol to register")
	flagRegister   = flag.Bool("register", false, "Register to Kontrol with your Koding Password")
	flagKontrolURL = flag.String("kontrol-url", "",
		"Change kontrol URL to be used for registration")

	// Update parameters
	flagUpdateInterval = flag.Duration("update-interval", time.Minute*5,
		"Change interval for checking for new updates")
	flagUpdateURL = flag.String("update-url",
		"https://s3.amazonaws.com/koding-klient/"+protocol.Environment+"/latest-version.txt",
		"Change update endpoint for latest version")

	// Vagrant flags
	flagVagrantHome = flag.String("vagrant-home", "", "Change Vagrant home path")

	// Tunnel flags
	flagTunnelServerAddr = flag.String("tunnel-server", "", "Tunnel server address")
	flagTunnelLocalAddr  = flag.String("tunnel-local", "", "Address of local server to be tunneled (optional)")
)

func main() {
	// Call realMain instead of doing the work here so we can use
	// `defer` statements within the function and have them work properly.
	// (defers aren't called with os.Exit)
	os.Exit(realMain())
}

func realMain() int {
	flag.Parse()
	if *flagVersion {
		fmt.Println(protocol.Version)
		return 0
	}

	if *flagRegister {
		if err := registration.Register(*flagKontrolURL, *flagKiteHome, *flagUsername, *flagToken); err != nil {
			fmt.Fprintln(os.Stderr, err.Error())
			return 1
		}
		return 0
	}

	dbPath := ""
	vagrantHome := ""
	u, err := user.Current()
	if err == nil {
		dbPath = filepath.Join(u.HomeDir, "/.config/koding/klient.bolt")
		vagrantHome = filepath.Join(u.HomeDir, ".vagrant.d")
	}

	if *flagDBPath != "" {
		dbPath = *flagDBPath
	}

	if *flagVagrantHome != "" {
		vagrantHome = *flagVagrantHome
	} else if s := os.Getenv("VAGRANT_CWD"); s != "" {
		vagrantHome = s
	}

	conf := &app.KlientConfig{
		Name:             protocol.Name,
		Environment:      protocol.Environment,
		Region:           protocol.Region,
		Version:          protocol.Version,
		DBPath:           dbPath,
		IP:               *flagIP,
		Port:             *flagPort,
		RegisterURL:      *flagRegisterURL,
		KontrolURL:       *flagKontrolURL,
		Debug:            *flagDebug,
		UpdateInterval:   *flagUpdateInterval,
		UpdateURL:        *flagUpdateURL,
		ScreenrcPath:     *flagScreenrc,
		VagrantHome:      vagrantHome,
		TunnelServerAddr: *flagTunnelServerAddr,
		TunnelLocalAddr:  *flagTunnelLocalAddr,
	}

	a := app.NewKlient(conf)
	defer a.Close()

	// Run Forrest, Run!
	a.Run()

	return 0
}
