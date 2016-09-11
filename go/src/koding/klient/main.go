package main

import (
	"flag"
	"fmt"
	"os"
	"os/user"
	"path/filepath"
	"runtime"
	"time"

	"koding/config"
	"koding/klient/app"
	"koding/klient/protocol"
	"koding/klient/registration"
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
	flagKiteHome   = flag.String("kite-home", defaultKiteHome(), "Change kite home path")
	flagUsername   = flag.String("username", "", "Username to be registered to Kontrol")
	flagToken      = flag.String("token", "", "Token to be passed to Kontrol to register")
	flagRegister   = flag.Bool("register", false, "Register to Kontrol with your Koding Password")
	flagKontrolURL = flag.String("kontrol-url", "", "Change kontrol URL to be used for registration")

	// Update parameters
	flagUpdateInterval = flag.Duration("update-interval", time.Minute*5,
		"Change interval for checking for new updates")
	flagUpdateURL = flag.String("update-url",
		"",
		"Change update endpoint for latest version")

	// Vagrant flags
	flagVagrantHome = flag.String("vagrant-home", "", "Change Vagrant home path")

	// Tunnel flags
	flagTunnelName    = flag.String("tunnel-name", "", "Enable tunneling by setting non-empty tunnel name")
	flagTunnelKiteURL = flag.String("tunnel-kite-url", "", "Change default tunnel server kite URL")
	flagNoTunnel      = flag.Bool("no-tunnel", defaultNoTunnel(), "Force tunnel connection off")
	flagNoProxy       = flag.Bool("no-proxy", false, "Force TLS proxy for tunneled connection off")
	flagAutoupdate    = flag.Bool("autoupdate", false, "Force turn automatic updates on")

	// Upload log flags
	flagLogBucketRegion   = flag.String("log-bucket-region", defaultBucketRegion(), "Change bucket region to upload logs")
	flagLogBucketName     = flag.String("log-bucket-name", defaultBucketName(), "Change bucket name to upload logs")
	flagKeygenURL         = flag.String("log-keygen-url", defaultKeygenURL(), "Change keygen endpoint URL for bucket authorization")
	flagLogUploadInterval = flag.Duration("log-upload-interval", 90*time.Minute, "Change interval of upload logs")
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

func defaultKeygenURL() string {
	return config.Builtin.Endpoints.URL("kloud", protocol.Environment)
}

func defaultBucketName() string {
	return config.Builtin.Buckets.ByEnv("publiclogs", protocol.Environment).Name
}

func defaultBucketRegion() string {
	return config.Builtin.Buckets.ByEnv("publiclogs", protocol.Environment).Region
}

func main() {
	// Call realMain instead of doing the work here so we can use
	// `defer` statements within the function and have them work properly.
	// (defers aren't called with os.Exit)
	os.Exit(realMain())
}

func realMain() int {
	flag.Parse()

	// For forward-compatibility with go1.5+, where GOMAXPROCS is
	// always set to a number of available cores.
	runtime.GOMAXPROCS(runtime.NumCPU())

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
		dbPath = filepath.Join(u.HomeDir, filepath.FromSlash(".config/koding/klient.bolt"))
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
		Name:              protocol.Name,
		Environment:       protocol.Environment,
		Region:            protocol.Region,
		Version:           protocol.Version,
		DBPath:            dbPath,
		IP:                *flagIP,
		Port:              *flagPort,
		RegisterURL:       *flagRegisterURL,
		KontrolURL:        *flagKontrolURL,
		Debug:             *flagDebug,
		UpdateInterval:    *flagUpdateInterval,
		UpdateURL:         *flagUpdateURL,
		ScreenrcPath:      *flagScreenrc,
		VagrantHome:       vagrantHome,
		TunnelName:        *flagTunnelName,
		TunnelKiteURL:     *flagTunnelKiteURL,
		NoTunnel:          *flagNoTunnel,
		NoProxy:           *flagNoProxy,
		Autoupdate:        *flagAutoupdate,
		LogBucketRegion:   *flagLogBucketRegion,
		LogBucketName:     *flagLogBucketName,
		LogKeygenURL:      *flagKeygenURL,
		LogUploadInterval: *flagLogUploadInterval,
	}

	a := app.NewKlient(conf)
	defer a.Close()

	// Run Forrest, Run!
	a.Run()

	return 0
}
