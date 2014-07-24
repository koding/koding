package bongo

import (
	"github.com/koding/logging"

	"github.com/jinzhu/gorm"
)

type EventBus interface {
	Connect() error
	Close() error
	Publish(messageType string, data []byte) error
}

var B *Bongo

type Bongo struct {
	Broker EventBus
	DB     *gorm.DB
	log    logging.Logger
	Cache  Cache
}

func New(b EventBus, db *gorm.DB, l logging.Logger) *Bongo {
	return &Bongo{
		Broker: b,
		DB:     db,
		log:    l,
	}
}

func (b *Bongo) Connect() error {
	if err := b.Broker.Connect(); err != nil {
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

	// todo add gorm Close()
	return nil
}
