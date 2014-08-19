package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"os/signal"
	"syscall"
)

type Broker struct {
	Name               string
	ServiceGenericName string
	IP                 string
	Port               int
	CertFile           string
	KeyFile            string
	AuthExchange       string
	AuthAllExchange    string
	WebProtocol        string
}

type Config struct {
	BuildNumber int
	Environment string
	Regions     struct {
		Vagrant string
		SJ      string
		AWS     string
		Premium string
	}
	ProjectRoot     string
	UserSitesDomain string
	ContainerSubnet string
	VmPool          string
	Version         string
	Client          struct {
		StaticFilesBaseUrl string
		RuntimeOptions     struct {
			NewKontrol struct {
				Url string
			}
		}
	}
	Mongo          string
	MongoKontrol   string
	MongoMinWrites int
	Mq             struct {
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
	GoLogLevel        string
	Broker            Broker
	PremiumBroker     Broker
	BrokerKite        Broker
	PremiumBrokerKite Broker
	Loggr             struct {
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
	NewKites struct {
		UseTLS   bool
		CertFile string
		KeyFile  string
	}
	NewKontrol struct {
		Port           int
		UseTLS         bool
		CertFile       string
		KeyFile        string
		PublicKeyFile  string
		PrivateKeyFile string
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
			KodingHost string
			SocialHost string
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
	LogLevel             map[string]string
	Redis                string
	SubscriptionEndpoint string
}

// TODO: THIS IS ADDED SO ALL GO PACKAGES CLEANLY EXIT EVEN WHEN
// RUN WITH RERUN

func init() {

	go func() {
		signals := make(chan os.Signal, 1)
		signal.Notify(signals)
		for {
			signal := <-signals
			switch signal {
			case syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT, syscall.SIGSTOP:
				os.Exit(0)
			}
		}
	}()
}

func MustConfig(profile string) *Config {
	conf, err := readConfig("", profile)
	if err != nil {
		panic(err)
	}

	return conf
}

// MustEnv is like Env, but panics if the Config cannot be read successfully.
func MustEnv() *Config {
	conf, err := Env()
	if err != nil {
		panic(err)
	}

	return conf
}

// Env reads from the KONFIG_JSON environment variable and intitializes the
// Config struct
func Env() (*Config, error) {
	return readConfig("", "")
}

// TODO: Fix this shit below where dir and profile is not even used ...
func MustConfigDir(dir, profile string) *Config {
	conf, err := readConfig(dir, profile)
	if err != nil {
		panic(err)
	}

	return conf
}

func readConfig(configDir, profile string) (*Config, error) {
	jsonData := os.Getenv("KONFIG_JSON")
	if jsonData == "" {
		return nil, errors.New("KONFIG_JSON is not set")
	}

	conf := new(Config)
	err := json.Unmarshal([]byte(jsonData), &conf)
	if err != nil {
		return nil, fmt.Errorf("Configuration error, make sure KONFIG_JSON is set: %s\nConfiguration source output:\n%s\n",
			err.Error(), string(jsonData))
	}

	return conf, nil
}
