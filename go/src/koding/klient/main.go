package main

import (
	"encoding/base64"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"net/url"
	"os"
	"path/filepath"
	"runtime"
	"time"

	"koding/kites/config"
	"koding/klient/app"
	konfig "koding/klient/config"
	"koding/klient/klientsvc"
	"koding/klient/registration"
)

// TODO(rjeczalik): replace with multiconfig
var (
	flagIP          = flag.String("ip", "", "Change public ip")
	flagPort        = flag.Int("port", 56789, "Change running port")
	flagVersion     = flag.Bool("version", false, "Show version and exit")
	flagRegisterURL = flag.String("register-url", "", "Change register URL to kontrol")
	flagDebug       = flag.Bool("debug", false, "Debug mode")
	flagScreenrc    = flag.String("screenrc", "/opt/koding/etc/screenrc", "Default screenrc path")
	flagDBPath      = flag.String("dbpath", "", "Bolt DB database path. Must be absolute)")

	// Registration flags
	flagKiteHome   = flag.String("kite-home", "", "Change kite home path")
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
	flagLogBucketRegion   = flag.String("log-bucket-region", "", "Change bucket region to upload logs")
	flagLogBucketName     = flag.String("log-bucket-name", "", "Change bucket name to upload logs")
	flagLogUploadInterval = flag.Duration("log-upload-interval", 90*time.Minute, "Change interval of upload logs")

	// Metadata flags.
	flagMetadata     = flag.String("metadata", "", "Base64-encoded Koding metadata")
	flagMetadataFile = flag.String("metadata-file", "", "Koding metadata file")
)

func defaultNoTunnel() bool {
	return os.Getenv("KITE_NO_TUNNEL") == "1"
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
		fmt.Println(konfig.Version)
		return 0
	}

	debug := *flagDebug || konfig.Konfig.Debug

	if *flagRegister {
		kontrolURL := *flagKontrolURL
		if kontrolURL == "" {
			kontrolURL = konfig.Konfig.Endpoints.Kontrol().Public.String()
		}

		kiteHome := *flagKiteHome
		if kiteHome == "" {
			kiteHome = konfig.Konfig.KiteHome()
		}

		if err := registration.Register(kontrolURL, kiteHome, *flagUsername, *flagToken, debug); err != nil {
			fmt.Fprintln(os.Stderr, err)
			return 1
		}

		u, err := url.Parse(kontrolURL)
		if err != nil {
			log.Fatalf("failed to parse -kontrol-url: %s", err)
		}

		// Create new konfig.bolt with variables used during registration.
		kfg := &config.Konfig{
			KiteKeyFile: filepath.Join(kiteHome, "kite.key"),
			Endpoints: &config.Endpoints{
				Koding: config.NewEndpointURL(u),
			},
			PublicBucketName:   *flagLogBucketName,
			PublicBucketRegion: *flagLogBucketRegion,
		}

		if err := config.DumpToBolt("", config.Metadata{"konfig": kfg}, nil); err != nil {
			fmt.Fprintln(os.Stderr, err)
			return 1
		}

		return 0
	}

	dbPath := filepath.Join(config.CurrentUser.HomeDir, filepath.FromSlash(".config/koding/klient.bolt"))
	vagrantHome := filepath.Join(config.CurrentUser.HomeDir, ".vagrant.d")

	if *flagDBPath != "" {
		dbPath = *flagDBPath
	}

	if *flagVagrantHome != "" {
		vagrantHome = *flagVagrantHome
	} else if s := os.Getenv("VAGRANT_CWD"); s != "" {
		vagrantHome = s
	}

	conf := &app.KlientConfig{
		Name:              konfig.Name,
		Environment:       konfig.Environment,
		Region:            konfig.Region,
		Version:           konfig.Version,
		DBPath:            dbPath,
		IP:                *flagIP,
		Port:              *flagPort,
		RegisterURL:       *flagRegisterURL,
		KontrolURL:        *flagKontrolURL,
		Debug:             debug,
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
		LogUploadInterval: *flagLogUploadInterval,
		Metadata:          *flagMetadata,
		MetadataFile:      *flagMetadataFile,
	}

	if err := handleMetadata(conf); err != nil {
		log.Fatalf("error writing Koding metadata: %s", err)
	}

	if len(flag.Args()) != 0 {
		if err := handleInternalCommand(flag.Arg(0)); err != nil {
			log.Fatal(err)
		}

		return 0
	}

	a, err := app.NewKlient(conf)
	if err != nil {
		log.Fatal(err)
	}

	defer a.Close()
	a.Run()

	return 0
}

func handleInternalCommand(cmd string) (err error) {
	// The following commands are intended for internal use
	// only. They are used by kloud to install klient
	// where no kd is available.
	//
	// TODO(rjeczalik): we should bundle klient with kd
	// and have only 1 klient/kd distribution.
	switch cmd {
	case "config":
		err = printConfig()
	case "install":
		err = klientsvc.Install()
	case "start":
		err = klientsvc.Start()
	case "stop":
		err = klientsvc.Stop()
	case "uninstall":
		err = klientsvc.Uninstall()
	case "run":
		err = klientsvc.Install()
		if err != nil {
			break
		}

		err = klientsvc.Start()
	default:
		return fmt.Errorf("unrecognized command: %s", cmd)
	}

	if err != nil {
		return fmt.Errorf("internal command failed: %s", err)
	}

	return nil
}

func handleMetadata(conf *app.KlientConfig) error {
	if conf.Metadata != "" && conf.MetadataFile != "" {
		return errors.New("the -metadata and -metadata-file flags are exclusive")
	}

	if conf.Metadata != "" {
		p, err := base64.StdEncoding.DecodeString(conf.Metadata)
		if err != nil {
			return errors.New("failed to decode Koding metadata: " + err.Error())
		}

		conf.Metadata = string(p)
	}

	if conf.MetadataFile != "" {
		p, err := ioutil.ReadFile(conf.MetadataFile)
		if err != nil {
			return errors.New("failed to read Koding metadata file: " + err.Error())
		}

		conf.Metadata = string(p)
	}

	if conf.Metadata != "" {
		var m config.Metadata

		if err := json.Unmarshal([]byte(conf.Metadata), &m); err != nil {
			return errors.New("failed to decode Koding metadata: " + err.Error())
		}

		if err := config.DumpToBolt("", m, nil); err != nil {
			return errors.New("failed to write Koding metadata: " + err.Error())
		}

		konfig.Konfig = konfig.ReadKonfig() // re-read konfig after dumping metadata
	}

	return nil
}

func printConfig() error {
	enc := json.NewEncoder(os.Stdout)
	enc.SetIndent("", "\t")

	return enc.Encode(map[string]interface{}{
		"builtinKonfig": konfig.Builtin,
		"konfig":        konfig.Konfig,
	})
}
