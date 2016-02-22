package bongo

import (
	"errors"

	"github.com/cenkalti/backoff"
	"github.com/koding/broker"
	"github.com/koding/logging"
	"github.com/koding/redis"

	"github.com/jinzhu/gorm"
)

var (
	B *Bongo

	ErrRedisConnNotExist = errors.New("redis connection does not exist")
)

type Bongo struct {
	Broker *broker.Broker
	DB     *gorm.DB
	log    logging.Logger
	Cache  Cache
}

func New(b *broker.Broker, db *gorm.DB, l logging.Logger) *Bongo {
	return &Bongo{
		Broker: b,
		DB:     db,
		log:    l,
	}
}

func (b *Bongo) Connect() error {

	bo := backoff.NewExponentialBackOff()
	ticker := backoff.NewTicker(bo)
	defer ticker.Stop()

	var err error
	for _ = range ticker.C {
		if err = b.Broker.Connect(); err != nil {
			b.log.Error("err while connecting: %s  will retry...", err.Error())
			continue
		}

		break
	}

	if err != nil {
		return err
	}

	B = b

	b.log.Info("Bongo connected %t", true)
	// todo add gorm Connect()
	return nil
}

func (b *Bongo) Close() error {
	if err := b.Broker.Close(); err != nil {
		return err
	}
	b.log.Info("Bongo dis-connected %t", true)

	r, ok := b.Cache.(*redis.RedisSession)
	if ok {
		r.Close()
	}

	// todo add gorm Close()
	return nil
}

func (b *Bongo) MustGetRedisConn() *redis.RedisSession {
	r, ok := b.Cache.(*redis.RedisSession)
	if !ok {
		panic(ErrRedisConnNotExist)
	}

	return r
}
