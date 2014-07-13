package config

const (
	VagrantEnvName = "vagrant"
)

type (
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
	}
	Redis struct {
		URL   string
		DB    int
		Slave string
	}
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
