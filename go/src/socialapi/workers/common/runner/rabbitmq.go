package runner

import (
	"github.com/koding/logging"

	"github.com/koding/rabbitmq"
)

func NewRabbitMQ(conf *Config, log logging.Logger) *rabbitmq.RabbitMQ {
	return rabbitmq.New(createRabbitMqConf(conf), log)
}

func createRabbitMqConf(conf *Config) *rabbitmq.Config {
	return &rabbitmq.Config{
		Host:     conf.Mq.Host,
		Port:     conf.Mq.Port,
		Username: conf.Mq.Login,
		Password: conf.Mq.Password,
		Vhost:    conf.Mq.Vhost,
	}
}
