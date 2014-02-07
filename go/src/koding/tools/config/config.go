package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
)

type Config struct {
	BuildNumber int
	Environment string
	Regions     struct {
		Vagrant string
		SJ      string
		AWS     string
	}
	ProjectRoot     string
	UserSitesDomain string
	ContainerSubnet string
	VmPool          string
	Version         string
	Client          struct {
		StaticFilesBaseUrl string
	}
	Mongo        string
	MongoKontrol string
	Mq           struct {
		Host          string
		Port          int
		ComponentUser string
		Password      string
		Vhost         string
		LogLevel      string
	}
	Neo4j struct {
		Read    string
		Write   string
		Port    int
		Enabled bool
	}
	GoLogLevel string
	Broker     struct {
		IP              string
		Port            int
		CertFile        string
		KeyFile         string
		AuthExchange    string
		AuthAllExchange string
		WebProtocol     string
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
	ElasticSearch struct {
		Host  string
		Port  int
		Queue string
	}
	NewKontrol struct {
		Host     string
		Port     int
		CertFile string
		KeyFile  string
	}
	ProxyKite struct {
		Domain   string
		CertFile string
		KeyFile  string
	}
	Etcd []struct {
		Host string
		Port int
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
			URL  string
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
	TopicModifier struct {
		CronSchedule string
	}
	Slack struct {
		Token   string
		Channel string
	}
	Graphite struct {
		Use  bool
		Host string
		Port int
	}
	LogLevel map[string]string
	Redis    string
}

func MustConfig(profile string) *Config {
	conf, err := readConfig(profile)
	if err != nil {
		panic(err)
	}

	return conf
}

// readConfig reads and unmarshalls the appropriate config into the Config
// struct (which is used in many applications). It reads the config from the
// koding-config-manager  with command line flag -c. If there is no flag
// specified it tries to get the config from the environment variable
// "CONFIG".
func readConfig(profile string) (*Config, error) {
	if profile == "" {
		// this is needed also if you can't pass a flag into other packages, like testing.
		// otherwise it's impossible to inject the config paramater. For example:
		// this doesn't work  : go test -c "vagrant"
		// but this will work : CONFIG="vagrant" go test
		envProfile := os.Getenv("CONFIG")
		if envProfile == "" {
			return nil, errors.New("config.go: please specify a configuration profile via -c or set a CONFIG environment.")
		}

		profile = envProfile
	}

	cwd, err := os.Getwd()
	if err != nil {
		return nil, err
	}

	configPath := filepath.Join(cwd, "config", fmt.Sprintf("main.%s.json", profile))
	ok, err := exists(configPath)
	if err != nil {
		return nil, err
	}

	var conf *Config
	if ok {
		fmt.Printf("config.go: reading config from %s\n", configPath)
		conf, err = ReadJson(profile)
		if err != nil {
			return nil, err
		}
	} else {
		fmt.Println("config.go: reading config with koding-config-manager")
		conf, err = ReadConfigManager(profile)
		if err != nil {
			return nil, err
		}
	}

	return conf, nil
}

func ReadJson(profile string) (*Config, error) {
	pwd, err := os.Getwd()
	if err != nil {
		return nil, err
	}

	configPath := filepath.Join(pwd, "config", fmt.Sprintf("main.%s.json", profile))

	data, err := ioutil.ReadFile(configPath)
	if err != nil {
		return nil, err
	}

	conf := new(Config)
	err = json.Unmarshal(data, &conf)
	if err != nil {
		return nil, fmt.Errorf("Could not unmarshal configuration: %s\nConfiguration source output:\n%s\n",
			err.Error(), string(data))
	}

	return conf, nil
}

func ReadConfigManager(profile string) (*Config, error) {
	cmd := exec.Command("node", "-e", "require('koding-config-manager').printJson('main."+profile+"')")

	data, err := cmd.CombinedOutput()
	if err != nil {
		return nil, fmt.Errorf("Could not execute configuration source: %s\nConfiguration source output:\n%s\n",
			err.Error(), data)
	}

	conf := new(Config)
	err = json.Unmarshal(data, &conf)
	if err != nil {
		return nil, fmt.Errorf("Could not unmarshal configuration: %s\nConfiguration source output:\n%s\n",
			err.Error(), string(data))
	}

	// successfully unmarshalled into Current
	return conf, nil
}

// exists returns whether the given file or directory exists or not.
func exists(path string) (bool, error) {
	_, err := os.Stat(path)
	if err == nil {
		return true, nil
	}

	if os.IsNotExist(err) {
		return false, nil
	}

	return false, err
}
