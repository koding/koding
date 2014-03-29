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

var EventExchangeName = "BrokerMessageBus"
