package config

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"os/exec"
)

type Config struct {
	BuildNumber     int
	ProjectRoot     string
	UserSitesDomain string
	Client          struct {
		StaticFilesBaseUrl string
	}
	Mongo string
	Mq    struct {
		Host          string
		Port          int
		ComponentUser string
		Password      string
		Vhost         string
	}
	Neo4j struct {
		Read    string
		Write   string
		Port    int
		Enabled bool
	}
	Broker struct {
		IP       string
		Port     int
		CertFile string
		KeyFile  string
	}
	Loggr struct {
		Push   bool
		Url    string
		ApiKey string
	}
	Librato struct {
		Push     bool
		Email    string
		Token    string
		Interval int
	}
	Opsview struct {
		Push bool
		Host string
	}
	Kontrold struct {
		Api struct {
			Port int
		}
		Proxy struct {
			Port    int
			PortSSL int
			SSLIPS  string
		}
		Mongo struct {
			Host string
		}
		RabbitMq struct {
			Host     string
			Port     string
			Login    string
			Password string
			Vhost    string
		}
	}
}

var FileProfile string
var PillarProfile string
var Profile string
var Current Config
var LogDebug bool
var Verbose bool
var Uuid string

func init() {
	flag.StringVar(&FileProfile, "c", "", "Configuration profile from file")
	flag.StringVar(&PillarProfile, "p", "", "Configuration profile from saltstack pillar")
	flag.BoolVar(&LogDebug, "d", false, "Log debug messages")
	flag.BoolVar(&Verbose, "v", false, "Enable verbose mode")
	flag.StringVar(&Uuid, "u", "", "Enable kontrol mode")

	flag.Parse()
	if flag.NArg() != 0 {
		flag.PrintDefaults()
		os.Exit(1)
	}
	if FileProfile == "" && PillarProfile == "" {
		fmt.Println("Please specify a configuration profile via -c or -p.")
		flag.PrintDefaults()
		os.Exit(1)
	}
	if FileProfile != "" && PillarProfile != "" {
		fmt.Println("The flags -c and -p are exclusive.")
		flag.PrintDefaults()
		os.Exit(1)
	}

	var configCommand *exec.Cmd
	if FileProfile != "" {
		Profile = FileProfile
		configCommand = exec.Command("node", "-e", "require('koding-config-manager').printJson('main."+FileProfile+"')")
	}
	if PillarProfile != "" {
		Profile = PillarProfile
		configCommand = exec.Command("salt-call", "pillar.get", PillarProfile, "--output=json", "--log-level=warning")
	}

	configJSON, err := configCommand.CombinedOutput()
	if err != nil {
		fmt.Printf("Could not execute configuration source: %s\nConfiguration source output:\n%s\n", err.Error(), configJSON)
		os.Exit(1)
	}

	err = json.Unmarshal(configJSON, &Current)
	if err == nil && (Current == Config{}) {
		err = fmt.Errorf("Empty configuration.")
	}
	if err != nil {
		fmt.Printf("Could not unmarshal configuration: %s\nConfiguration source output:\n%s\n", err.Error(), configJSON)
		os.Exit(1)
	}
}
