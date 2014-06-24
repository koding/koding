package helper

import (
	"socialapi/config"
	"socialapi/db"
	"github.com/koding/logging"

	"github.com/koding/bongo"
	"github.com/koding/broker"
	"github.com/koding/rabbitmq"
)

func MustInitBongo(
	appName string,
	eventExchangeName string,
	c *config.Config,
	log logging.Logger,
) *bongo.Bongo {
	rmqConf := &rabbitmq.Config{
		Host:     c.Mq.Host,
		Port:     c.Mq.Port,
		Username: c.Mq.Username,
		Password: c.Mq.Password,
		Vhost:    c.Mq.Vhost,
	}

	bConf := &broker.Config{
		RMQConfig:    rmqConf,
		ExchangeName: eventExchangeName,
	}

	db := db.MustInit(c)

	broker := broker.New(appName, bConf, log)
	bongo := bongo.New(broker, db, log)
	err := bongo.Connect()
	if err != nil {
		log.Fatal("Error while starting bongo, exiting err: %s", err.Error())
	}

	return bongo
}
