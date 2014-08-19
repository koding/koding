package config

const (
	// Special env name for vagrant
	VagrantEnvName = "vagrant"
)

type (
	// Config holds all the configuration variables of socialapi
	Config struct {
		// Postres holds connection credentials for postgresql
		Postgres Postgres

		// Mq holds connction credentials for rabbitmq
		Mq Mq

		// Redis holds connection string for redis
		Redis Redis

		// Mongo holds full connection string
		Mongo string `env:"key=KONFIG_SOCIALAPI_MONGO                                 required"`

		// Environment holds the environment of the the running application
		Environment string `env:"key=KONFIG_SOCIALAPI_ENVIRONMENT                     required"`

		// Region holds the region of the the running application
		Region string `env:"key=KONFIG_SOCIALAPI_REGION                               required"`

		// Hostname is the web end point the app
		Hostname string `env:"key=KONFIG_SOCIALAPI_HOSTNAME                           required"`

		// Email holds the required configuration data for email related workers
		Email Email

		// Sitemap holds configuration for Sitemap workers
		Sitemap Sitemap

		// Algolia holds configuration parameters for Aloglia search engine
		Algolia Algolia

		// Mixpanel holds configuration parameters for mixpanel
		Mixpanel Mixpanel

		// Limits holds limits for various cases
		Limits Limits

		// random access configs
		EventExchangeName string `env:"key=KONFIG_SOCIALAPI_EVENTEXCHANGENAME               required  default=BrokerMessageBus"`
		DisableCaching    bool   `env:"key=KONFIG_SOCIALAPI_DISABLECACHING                  required  default=false"`
		Debug             bool   `env:"key=KONFIG_SOCIALAPI_DEBUG 					       		      default=false"`

		// just a temp hack
		Host string
		Port string
	}

	// Postgres holds Postgresql database related configuration
	Postgres struct {
		Host     string `env:"key=KONFIG_SOCIALAPI_POSTGRES_HOST                            required"`
		Port     int    `env:"key=KONFIG_SOCIALAPI_POSTGRES_PORT                            required  default=5432"`
		Username string `env:"key=KONFIG_SOCIALAPI_POSTGRES_USERNAME                        required  default=socialapplication"`
		Password string `env:"key=KONFIG_SOCIALAPI_POSTGRES_PASSWORD                        required  default=socialapplication"`
		DBName   string `env:"key=KONFIG_SOCIALAPI_POSTGRES_DBNAME                          required  default=social"`
	}

	// Mq holds Rabbitmq related configuration
	Mq struct {
		Host     string `env:"key=KONFIG_SOCIALAPI_MQ_HOST                                  required"`
		Port     int    `env:"key=KONFIG_SOCIALAPI_MQ_PORT                                  required"`
		Login    string `env:"key=KONFIG_SOCIALAPI_MQ_LOGIN                                 required"`
		Password string `env:"key=KONFIG_SOCIALAPI_MQ_PASSWORD                              required"`
		Vhost    string `env:"key=KONFIG_SOCIALAPI_MQ_VHOST                                 required"`
	}

	// Redis holds Redis related config
	Redis struct {
		URL string `env:"key=KONFIG_SOCIALAPI_REDIS_URL                                    required"`
		DB  int    `env:"key=KONFIG_SOCIALAPI_REDIS_DB                                                  default=0"`
	}

	// Email holds Email Workers' config
	Email struct {
		Host            string `env:"key=KONFIG_SOCIALAPI_EMAIL_HOST                     required"`
		Protocol        string `env:"key=KONFIG_SOCIALAPI_EMAIL_PROTOCOL                 required"`
		DefaultFromMail string `env:"key=KONFIG_SOCIALAPI_EMAIL_DEFAULTFROMMAIL          required"`
		DefaultFromName string `env:"key=KONFIG_SOCIALAPI_EMAIL_DEFAULTFROMNAME          required"`
		ForcedRecipient string `env:"key=KONFIG_SOCIALAPI_EMAIL_FORCEDRECIPIENT"`
		Username        string `env:"key=KONFIG_SOCIALAPI_EMAIL_USERNAME                 required"`
		Password        string `env:"key=KONFIG_SOCIALAPI_EMAIL_PASSWORD                 required"`
		TemplateRoot    string `env:"key=KONFIG_SOCIALAPI_EMAIL_TEMPLATEROOT 	        default=workers/sitemap/files/"`
	}

	// Sitemap holds Sitemap Workers' config
	Sitemap struct {
		RedisDB int `env:"key=KONFIG_SOCIALAPI_SITEMAP_REDISDB"`
	}

	// Algolia holds Algolia service credentials
	Algolia struct {
		AppId        string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APPID                        required"`
		ApiKey       string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APIKEY                       required"`
		ApiSecretKey string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_APISECRETKEY                 required"`
		IndexSuffix  string `env:"key=KONFIG_SOCIALAPI_ALGOLIA_INDEXSUFFIX                  required"`
	}

	// Mixpanel holds mixpanel credentials
	Mixpanel struct {
		Token   string `env:"key=KONFIG_SOCIALAPI_MIXPANEL_TOKEN                            required"`
		Enabled bool   `env:"key=KONFIG_SOCIALAPI_MIXPANEL_ENABLED"`
	}

	// Limits holds application's various limits
	Limits struct {
		MessageBodyMinLen    int    `env:"key=KONFIG_SOCIALAPI_LIMITS_MESSAGEBODYMINLEN     required default=1"`
		PostThrottleDuration string `env:"key=KONFIG_SOCIALAPI_LIMITS_POSTTHROTTLEDURATION  required default=5s"`
		PostThrottleCount    int    `env:"key=KONFIG_SOCIALAPI_LIMITS_POSTTHROTTLECOUNT     required default=20"`
	}
)
