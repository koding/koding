package config

type (
	Config struct {
		Postgres          Postgres
		Mq                Mq
		Limits            Limits
		EventExchangeName string
		Redis             string
		Mongo             string
		Environment       string
		Cache             Cache
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
		MessageBodyMinLen int
	}
	Cache struct {
		Notification bool
	}
)
