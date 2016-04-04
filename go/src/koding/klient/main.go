package main

import (
	"flag"
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"time"

	"koding/klient/app"
	"koding/klient/protocol"
	"koding/klient/registration"
)

func defaultKiteHome() string {
	if u, err := user.Current(); err == nil {
		return filepath.Join(u.HomeDir, ".kite")
	}
	return "."
}

func defaultNoTunnel() bool {
	return os.Getenv("KITE_NO_TUNNEL") == "1"
}

var (
	flagIP          = flag.String("ip", "", "Change public ip")
	flagPort        = flag.Int("port", 56789, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
	flagDebug       = flag.Bool("debug", false, "Debug mode")
	flagScreenrc    = flag.String("screenrc", "/opt/koding/etc/screenrc", "Default screenrc path")
	flagDBPath      = flag.String("dbpath", "", "Bolt DB database path. Must be absolute)")

	// Registration flags
	flagKiteHome   = flag.String("kite-home", defaultKiteHome(), "Change kite home path")
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
	flagTunnelName    = flag.String("tunnel-name", "", "Enable tunneling by setting non-empty tunnel name")
	flagTunnelKiteURL = flag.String("tunnel-kite-url", "", "Change default tunnel server kite URL")
	flagNoTunnel      = flag.Bool("no-tunnel", defaultNoTunnel(), "Force tunnel connection off")
	flagNoProxy       = flag.Bool("no-proxy", false, "Force TLS proxy for tunneled connection off")
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
		if err := registration.Register(*flagKontrolURL, *flagKiteHome, *flagUsername, *flagToken, *flagDebug); err != nil {
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
		Name:           protocol.Name,
		Environment:    protocol.Environment,
		Region:         protocol.Region,
		Version:        protocol.Version,
		DBPath:         dbPath,
		IP:             *flagIP,
		Port:           *flagPort,
		RegisterURL:    *flagRegisterURL,
		KontrolURL:     *flagKontrolURL,
		Debug:          *flagDebug,
		UpdateInterval: *flagUpdateInterval,
		UpdateURL:      *flagUpdateURL,
		ScreenrcPath:   *flagScreenrc,
		VagrantHome:    vagrantHome,
		TunnelName:     *flagTunnelName,
		TunnelKiteURL:  *flagTunnelKiteURL,
		NoTunnel:       *flagNoTunnel,
		NoProxy:        *flagNoProxy,
	}

	a := app.NewKlient(conf)
	defer a.Close()

	// Run Forrest, Run!
	a.Run()

	return 0
}
