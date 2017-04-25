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
	"koding/kites/config/configstore"
	"koding/kites/metrics"
	"koding/klient/app"
	konfig "koding/klient/config"
	"koding/klient/klientsvc"
	"koding/klient/registration"
)

// TODO: workaround for #10057
var f = flag.NewFlagSet(os.Args[0], flag.ExitOnError)

var (
	flagIP          = f.String("ip", "", "Change public ip")
	flagPort        = f.Int("port", 56789, "Change running port")
	flagVersion     = f.Bool("version", false, "Show version and exit")
	flagRegisterURL = f.String("register-url", "", "Change register URL to kontrol")
	flagDebug       = f.Bool("debug", false, "Debug mode")
	flagScreenrc    = f.String("screenrc", "/opt/koding/embedded/etc/screenrc", "Default screenrc path")
	flagScreenTerm  = f.String("screen-term", "", "Overwrite $TERM for screen")

	// Registration flags
	flagUsername   = f.String("username", "", "Username to be registered to Kontrol")
	flagToken      = f.String("token", "", "Token to be passed to Kontrol to register")
	flagRegister   = f.Bool("register", false, "Register to Kontrol with your Koding Password")
	flagKontrolURL = f.String("kontrol-url", "", "Change kontrol URL to be used for registration")

	// Update parameters
	flagUpdateInterval = f.Duration("update-interval", time.Minute*5,
		"Change interval for checking for new updates")
	flagUpdateURL = f.String("update-url",
		"",
		"Change update endpoint for latest version")

	// Vagrant flags
	flagVagrantHome = f.String("vagrant-home", "", "Change Vagrant home path")

	// Tunnel flags
	flagTunnelName    = f.String("tunnel-name", "", "Enable tunneling by setting non-empty tunnel name")
	flagTunnelKiteURL = f.String("tunnel-kite-url", "", "Change default tunnel server kite URL")
	flagNoTunnel      = f.Bool("no-tunnel", defaultNoTunnel(), "Force tunnel connection off")
	flagNoProxy       = f.Bool("no-proxy", false, "Force TLS proxy for tunneled connection off")
	flagAutoupdate    = f.Bool("autoupdate", false, "Force turn automatic updates on")

	// Upload log flags
	flagLogBucketRegion   = f.String("log-bucket-region", "", "Change bucket region to upload logs")
	flagLogBucketName     = f.String("log-bucket-name", "", "Change bucket name to upload logs")
	flagLogUploadInterval = f.Duration("log-upload-interval", 90*time.Minute, "Change interval of upload logs")

	// Metadata flags.
	flagMetadata     = f.String("metadata", "", "Base64-encoded Koding metadata")
	flagMetadataFile = f.String("metadata-file", "", "Koding metadata file")
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
	f.Var(config.CurrentUser, "metadata-user", "Overwrite default user to store the metadata for.")
	f.Parse(os.Args[1:])

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

		koding, err := url.Parse(kontrolURL)
		if err != nil {
			log.Fatalf("failed to parse -kontrol-url: %s", err)
		}

		// TODO(rjeczalik): rework client to display KODING_URL instead of KONTROLURL
		koding.Path = ""

		if err := registration.Register(koding, *flagUsername, *flagToken, debug); err != nil {
			fmt.Fprintln(os.Stderr, "registration failed:", err)
			return 1
		}

		return 0
	}

	vagrantHome := filepath.Join(config.CurrentUser.HomeDir, ".vagrant.d")

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
		IP:                *flagIP,
		Port:              *flagPort,
		RegisterURL:       *flagRegisterURL,
		KontrolURL:        *flagKontrolURL,
		Debug:             debug,
		UpdateInterval:    *flagUpdateInterval,
		UpdateURL:         *flagUpdateURL,
		ScreenrcPath:      *flagScreenrc,
		ScreenTerm:        *flagScreenTerm,
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

	if len(f.Args()) != 0 {
		if err := handleInternalCommand(f.Arg(0), f.Args()[1:]...); err != nil {
			log.Fatal(err)
		}

		return 0
	}

	a, err := app.NewKlient(conf)
	if err != nil {
		log.Fatal(err)
	}

	defer a.Close()

	if os.Getenv("GENERATE_DATADOG_DASHBOARD") != "" {
		metrics.CreateMetricsDash()
	}

	a.Run()

	return 0
}

func handleInternalCommand(cmd string, args ...string) (err error) {
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
		var m configstore.Metadata

		if err := json.Unmarshal([]byte(conf.Metadata), &m); err != nil {
			return errors.New("failed to decode Koding metadata: " + err.Error())
		}

		if err := configstore.WriteMetadata(m); err != nil {
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
