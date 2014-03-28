package helper

import (
	"koding/tools/config"
	"socialapi/db"

	"github.com/koding/bongo"
	"github.com/koding/broker"
	"github.com/koding/rabbitmq"
)

func MustInitBongo(c *config.Config) *bongo.Bongo {
	rmqConf := &rabbitmq.Config{
		Host:     c.Mq.Host,
		Port:     c.Mq.Port,
		Username: c.Mq.ComponentUser,
		Password: c.Mq.Password,
		Vhost:    c.Mq.Vhost,
	}

	bConf := &broker.Config{
		RMQConfig: rmqConf,
	}
	broker := broker.New(bConf, log)
	bongo := bongo.New(broker, db.DB, log)
	err := Bongo.Connect()
	if err != nil {
		panic(err)
	}

	return bongo
}
