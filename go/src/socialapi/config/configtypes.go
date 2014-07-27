package config

const (
	// Special env name for vagrant
	VagrantEnvName = "vagrant"
)

type (
	// Config holds all the configuration variables of socialapi
	Config struct {
		Postgres          Postgres
		Mq                Mq
		Limits            Limits
		EventExchangeName string
		Redis             Redis
		Mongo             string
		Environment       string
		Region            string
		Uri               string
		SendGrid          SendGrid
		EmailNotification EmailNotification
		Sitemap           Sitemap
		FlagDebugMode     bool
		DisableCaching    bool
	}
	// Redis holds Redis related config
	Redis struct {
		URL   string
		DB    int
		Slave string
	}
	// Postgres holds Postgresql database related configuration
	Postgres struct {
		Host     string
		Port     int
		Username string
		Password string
		DBName   string
	}
	Mq struct {
		Host     string
		Port     int
		Username string
		Password string
		Vhost    string
	}
	Limits struct {
		MessageBodyMinLen    int
		PostThrottleDuration string
		PostThrottleCount    int
	}
	SendGrid struct {
		Username        string
		Password        string
		FromName        string
		FromMail        string
		ForcedRecipient string
	}
	EmailNotification struct {
		TemplateRoot string
	}
	Sitemap struct {
		RedisDB int
	}
)
