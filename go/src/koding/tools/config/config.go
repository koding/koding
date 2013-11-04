package config

import (
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"os"
	"os/exec"
	"os/signal"
	"syscall"
)

type Config struct {
	BuildNumber     int
	ProjectRoot     string
	UserSitesDomain string
	ContainerSubnet string
	VmPool          string
	Version         string
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
		IP              string
		Port            int
		CertFile        string
		KeyFile         string
		AuthExchange    string
		AuthAllExchange string
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
		Vhost    string
		Overview struct {
			ApiPort    int
			ApiHost    string
			Port       int
			SwitchHost string
		}
		Api struct {
			Port int
		}
		Proxy struct {
			Port    int
			PortSSL int
			FTPIP   string
		}
	}
	FollowFeed struct {
		Host          string
		Port          int
		ComponentUser string
		Password      string
		Vhost         string
	}
	Statsd struct {
		Use  bool
		Ip   string
		Port int
	}
}

var FileProfile string
var PillarProfile string
var Profile string
var Current Config
var LogDebug bool
var Uuid string
var Host string
var BrokerDomain string
var Region string
var VMProxies bool // used to enable ports for users
var Skip int
var Count int

func init() {
	flag.StringVar(&FileProfile, "c", "", "Configuration profile from file")
	flag.StringVar(&FileProfile, "config", "", "Alias for -c")
	flag.StringVar(&PillarProfile, "p", "", "Configuration profile from saltstack pillar")
	flag.BoolVar(&LogDebug, "d", false, "Log debug messages")
	flag.StringVar(&Uuid, "u", "", "Enable kontrol mode")
	flag.StringVar(&Host, "h", "", "Hostname to be resolved")
	flag.StringVar(&BrokerDomain, "a", "", "Send kontrol a custom domain istead of os.Hostname")
	flag.StringVar(&BrokerDomain, "domain", "", "Alias for -a")
	flag.StringVar(&Region, "r", "", "Region")
	flag.IntVar(&Skip, "s", 0, "Define how far to skip ahead")
	flag.IntVar(&Count, "l", 1000, "Count for items to process")
	flag.BoolVar(&VMProxies, "v", false, "Enable ports for VM users (1024-10000)")

	flag.Parse()

	err := readConfig()
	if err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	sigChannel := make(chan os.Signal)
	signal.Notify(sigChannel, syscall.SIGUSR2)
	go func() {
		for _ = range sigChannel {
			LogDebug = !LogDebug
			fmt.Printf("config.LogDebug: %v\n", LogDebug)
		}
	}()

}

// readConfig reads and unmarshalls the appropriate config into the Config
// struct (which is used in many applications). It either reads the config
// from the koding-config-manager or from salt-pillar with command line flag
// -c and -p. They are exclusive, which means you only can use one. If there
// is no flag specified it tries to get the config from the environment
// variable "CONFIG".
func readConfig() error {
	if flag.NArg() != 0 {
		return errors.New("You passed extra unused arguments.")
	}

	if FileProfile == "" && PillarProfile == "" {
		// this is needed also if you can't pass a flag into other packages, like testing.
		// otherwise it's impossible to inject the config paramater. For example:
		// this doesn't work  : go test -c "vagrant"
		// but this will work : CONFIG="vagrant" go test
		envProfile := os.Getenv("CONFIG")
		if envProfile == "" {
			return errors.New("Please specify a configuration profile via -c or -p or set a CONFIG environment.")
		}

		FileProfile = envProfile
	}

	if FileProfile != "" && PillarProfile != "" {
		return errors.New("The flags -c and -p are exclusive.")
	}

	if FileProfile != "" {
		Profile = FileProfile
		err := readConfigManager(FileProfile)
		if err != nil {
			return err
		}
	}

	if PillarProfile != "" {
		Profile = PillarProfile
		err := readPillar(PillarProfile)
		if err != nil {
			return err
		}
	}

	return nil

}

func readConfigManager(profile string) error {
	cmd := exec.Command("node", "-e", "require('koding-config-manager').printJson('main."+profile+"')")
	return initializeConfig(cmd)
}

func readPillar(profile string) error {
	cmd := exec.Command("salt-call", "pillar.get", profile, "--output=json", "--log-level=warning")
	return initializeConfig(cmd)
}

func initializeConfig(cmd *exec.Cmd) error {
	config, err := cmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("Could not execute configuration source: %s\nConfiguration source output:\n%s\n",
			err.Error(), config)
	}

	err = json.Unmarshal(config, &Current)
	if err == nil && (Current == Config{}) {
		err = fmt.Errorf("Empty configuration.")
	}

	if err != nil {
		return fmt.Errorf("Could not unmarshal configuration: %s\nConfiguration source output:\n%s\n",
			err.Error(), config)
	}

	// successfully unmarshalled into Current
	return nil
}
