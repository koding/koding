package config

type (
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

	Config struct {
		Postgres          Postgres
		Mq                Mq
		EventExchangeName string
		Mongo             string
	}
)

func Read(env string) *Config {
	return &Config{
		// set postgres connection config
		Postgres: Postgres{
			Host:     "localhost",
			Port:     5432,
			Username: "postgres",
			Password: "123123123",
			DBName:   "social",
		},
		EventExchangeName: "BrokerMessageBus",
		Mongo:             "localhost:27017/koding",
		Mq: Mq{
			Host:     "localhost",
			Port:     5672,
			Username: "PROD-k5it50s4676pO9O",
			Password: "djfjfhgh4455__5",
			Vhost:    "/",
		},
	}
}
