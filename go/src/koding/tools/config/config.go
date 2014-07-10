package config

import (
	"encoding/json"
	"errors"
	"fmt"
	"os"
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

func MustConfig(profile string) *Config {
	conf, err := readConfig("", profile)
	if err != nil {
		panic(err)
	}

	return conf
}

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
