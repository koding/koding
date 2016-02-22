package runner

import (
	"github.com/koding/logging"
	"github.com/koding/metrics"

	"github.com/koding/bongo"
	"github.com/koding/broker"
	"github.com/koding/rabbitmq"
)

func MustInitBongo(
	appName string,
	eventExchangeName string,
	c *Config,
	log logging.Logger,
	metrics *metrics.Metrics,
	debug bool,
) *bongo.Bongo {
	rmqConf := &rabbitmq.Config{
		Host:     c.Mq.Host,
		Port:     c.Mq.Port,
		Username: c.Mq.Login,
		Password: c.Mq.Password,
		Vhost:    c.Mq.Vhost,
	}

	bConf := &broker.Config{
		RMQConfig:    rmqConf,
		ExchangeName: eventExchangeName,
		QOS:          10,
	}

	db := MustInitDB(c, log, debug)

	broker := broker.New(appName, bConf, log)
	// set metrics for broker
	broker.Metrics = metrics

	bongo := bongo.New(broker, db, log)
	err := bongo.Connect()
	if err != nil {
		log.Fatal("Error while starting bongo, exiting err: %s", err.Error())
	}

	log.Info("Caching disabled: %v", c.DisableCaching)
	if !c.DisableCaching {
		redisConn, err := InitRedisConn(c)
		if err != nil {
			log.Critical("Bongo couldnt connect to redis, caching will not be available Err: %s", err.Error())
		} else {
			bongo.Cache = redisConn
		}
	}

	return bongo
}
