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
			Kites struct {
				DisableWebSocketByDefault bool `json:"disableWebSocketByDefault"`
				Stack                     struct {
					Force    bool `json:"force"`
					NewKites bool `json:"newKites"`
				} `json:"stack"`
				Kontrol struct {
					Username string `json:"username"`
				} `json:"kontrol"`
				Os struct {
					Version string `json:"version"`
				} `json:"os"`
				Terminal struct {
					Version string `json:"version"`
				} `json:"terminal"`
				Klient struct {
					Version string `json:"version"`
				} `json:"klient"`
				Kloud struct {
					Version string `json:"version"`
				} `json:"kloud"`
			} `json:"kites"`
			Algolia struct {
				AppId       string `json:"appId"`
				ApiKey      string `json:"apiKey"`
				IndexSuffix string `json:"indexSuffix"`
			} `json:"algolia"`
			LogToExternal   bool   `json:"logToExternal"`
			SuppressLogs    bool   `json:"suppressLogs"`
			LogToInternal   bool   `json:"logToInternal"`
			AuthExchange    string `json:"authExchange"`
			Environment     string `json:"environment"`
			Version         string `json:"version"`
			ResourceName    string `json:"resourceName"`
			UserSitesDomain string `json:"userSitesDomain"`
			LogResourceName string `json:"logResourceName"`
			SocialApiUri    string `json:"socialApiUri"`
			ApiUri          string `json:"apiUri"`
			MainUri         string `json:"mainUri"`
			SourceMapsUri   string `json:"sourceMapsUri"`
			Broker          struct {
				Uri string `json:"uri"`
			} `json:"broker"`
			AppsUri            string `json:"appsUri"`
			UploadsUri         string `json:"uploadsUri"`
			UploadsUriForGroup string `json:"uploadsUriForGroup"`
			FileFetchTimeout   int    `json:"fileFetchTimeout"`
			UserIdleMs         int    `json:"userIdleMs"`
			Embedly            struct {
				ApiKey string `json:"apiKey"`
			} `json:"embedly"`
			Github struct {
				ClientId string `json:"clientId"`
			} `json:"github"`
			Newkontrol struct {
				Url string `json:"url"`
			} `json:"newkontrol"`
			SessionCookie struct {
				MaxAge int  `json:"maxAge"`
				Secure bool `json:"secure"`
			} `json:"sessionCookie"`
			Troubleshoot struct {
				IdleTime    int    `json:"idleTime"`
				ExternalUrl string `json:"externalUrl"`
			} `json:"troubleshoot"`
			Recaptcha string `json:"recaptcha"`
			Stripe    struct {
				Token string `json:"token"`
			} `json:"stripe"`
			ExternalProfiles struct {
				Google struct {
					Nicename string `json:"nicename"`
				} `json:"google"`
				Linkedin struct {
					Nicename string `json:"nicename"`
				} `json:"linkedin"`
				Twitter struct {
					Nicename string `json:"nicename"`
				} `json:"twitter"`
				Odesk struct {
					Nicename    string `json:"nicename"`
					UrlLocation string `json:"urlLocation"`
				} `json:"odesk"`
				Facebook struct {
					Nicename    string `json:"nicename"`
					UrlLocation string `json:"urlLocation"`
				} `json:"facebook"`
				Github struct {
					Nicename    string `json:"nicename"`
					UrlLocation string `json:"urlLocation"`
				} `json:"github"`
			} `json:"externalProfiles"`
			EntryPoint struct {
				Slug string `json:"slug"`
				Type string `json:"type"`
			} `json:"entryPoint"`
			Roles       []string      `json:"roles"`
			Permissions []interface{} `json:"permissions"`
		}
	}
	Mongo          string
	MongoKontrol   string
	MongoMinWrites int
	Mq             struct {
		Host     string
		Port     int
		Login    string
		Password string
		Vhost    string
		LogLevel string
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
	Gowebserver          struct {
		Port int
	}
	Rerouting struct {
		Port int
	}
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
