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
	BuildNumber     int
	Environment     string
	ProjectRoot     string
	UserSitesDomain string
	Version         string
	Client          struct {
		StaticFilesBaseUrl string
		RuntimeOptions     RuntimeOptions
	}
	Mongo string
	Mq    struct {
		Host     string
		Port     int
		Login    string
		Password string
		Vhost    string
		LogLevel string
	}
	Broker            Broker
	PremiumBroker     Broker
	BrokerKite        Broker
	PremiumBrokerKite Broker
	Slack             struct {
		Token   string
		Channel string
	}
	LogLevel map[string]string
	Redis    struct {
		Url string
	}
	SubscriptionEndpoint string
	Gowebserver          struct {
		Port int
	}
	Rerouting struct {
		Port int
	}
	SocialApi struct {
		ProxyUrl     string
		CustomDomain struct {
			Public string
			Local  string
		}
	}
	Vmwatcher struct {
		Port           string
		AwsKey         string
		AwsSecret      string
		KloudSecretKey string
		KloudAddr      string
	}
	Segment        string
	GatherIngestor struct {
		Port int
	}
	Mailgun struct {
		Domain     string
		PrivateKey string
		PublicKey  string
	}
}

type RuntimeOptions struct {
	Kites struct {
		DisableWebSocketByDefault bool `json:"disableWebSocketByDefault"`
		Kontrol                   struct {
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
	SuppressLogs    bool   `json:"suppressLogs"`
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
	IntercomAppId      string `json:"intercomAppId"`
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
	Stripe struct {
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
		Facebook struct {
			Nicename    string `json:"nicename"`
			UrlLocation string `json:"urlLocation"`
		} `json:"facebook"`
		Github struct {
			Nicename    string `json:"nicename"`
			UrlLocation string `json:"urlLocation"`
		} `json:"github"`
		Gitlab struct {
			Nicename string `json:"nicename"`
		} `json:"gitlab"`
	} `json:"externalProfiles"`
	EntryPoint struct {
		Slug string `json:"slug"`
		Type string `json:"type"`
	} `json:"entryPoint"`
	Roles       []string      `json:"roles"`
	Permissions []interface{} `json:"permissions"`
	SiftScience string        `json:"siftScience"`
	Paypal      struct {
		FormUrl string `json:"formUrl"`
	} `json:"paypal"`
	Pubnub struct {
		SubscribeKey string `json:"subscribekey"`
		Enabled      bool   `json:"enabled"`
		SSL          bool   `json:"ssl"`
	} `json:"pubnub"`
	Collaboration struct {
		Timeout int `json:"timeout"`
	} `json:"collaboration"`
	PaymentBlockDuration float64 `json:"paymentBlockDuration"`
	DisabledFeatures     struct {
		Moderation bool `json:"moderation"`
		Teams      bool `json:"teams"`
		BotChannel bool `json:"botchannel"`
	} `json:"disabledFeatures"`
	ContentRotatorUrl string `json:"contentRotatorUrl"`
	Integration       struct {
		Url string `json:"url"`
	} `json:"integration"`
	WebhookMiddleware struct {
		Url string `json:"url"`
	} `json:"webhookMiddleware"`
	Google struct {
		ApiKey string `json:"apiKey"`
	} `json:"google"`
	Recaptcha struct {
		Key     string `json:"key"`
		Enabled bool   `json:"enabled"`
	} `json:"recaptcha"`
	Domains struct {
		Base string `json:"base"`
		Mail string `json:"mail"`
		Main string `json:"main"`
		Port string `json:"port"`
	} `json:"domains"`
	Gitlab struct {
		Team string `json:"team"`
	} `json:"gitlab"`
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
